
using GymManagement.api.Models;
using Npgsql;
using NpgsqlTypes;

namespace GymManagement.api.Services;

public class AsistenciaPersonalService
{
    private readonly string _connectionString;

    public AsistenciaPersonalService(IConfiguration configuration)
    {
        _connectionString =
            configuration.GetConnectionString("PostgreSQL")
            ?? throw new InvalidOperationException(
                "No existe la conexión PostgreSQL.");
    }

    public async Task<long> RegistrarEntrada(
        RegistrarAsistenciaPersonalRequest request,
        int idAdministrador)
    {
        request.Validar();

        if (idAdministrador <= 0)
            throw new UnauthorizedAccessException();

        await using var connection =
            new NpgsqlConnection(_connectionString);

        await connection.OpenAsync();

        await using var transaction =
            await connection.BeginTransactionAsync();

        // Validar que el empleado exista y esté activo.
        await using (var validar = new NpgsqlCommand(
            """
            SELECT EXISTS (
                SELECT 1
                FROM public.personal p
                INNER JOIN public.usuarios u
                    ON u.id_usuario = p.id_usuario
                WHERE p.id_personal = @id_personal
                  AND u.estatus = 'Activo'
                  AND p.fecha_baja IS NULL
            );
            """, connection, transaction))
        {
            validar.Parameters.AddWithValue(
                "id_personal", request.IdPersonal);

            var activo = (bool)(await validar.ExecuteScalarAsync()
                ?? false);

            if (!activo)
                throw new ArgumentException(
                    "El empleado no existe o está inactivo.");
        }

        // Registrar la entrada laboral.
        await using var comando = new NpgsqlCommand(
            """
            INSERT INTO public.personal_asistencias
                (id_personal, fecha, hora_entrada, registrado_por)
            VALUES
                (@id_personal, @fecha, @hora_entrada, @registrado_por)
            RETURNING id_asistencia_personal;
            """, connection, transaction);

        comando.Parameters.AddWithValue(
            "id_personal", request.IdPersonal);

        comando.Parameters.AddWithValue(
            "fecha", NpgsqlDbType.Date, request.Fecha);

        comando.Parameters.AddWithValue(
            "hora_entrada", NpgsqlDbType.Time, request.HoraEntrada);

        comando.Parameters.AddWithValue(
            "registrado_por", idAdministrador);

        try
        {
            var resultado = await comando.ExecuteScalarAsync();

            var idAsistencia = Convert.ToInt64(resultado);

            await transaction.CommitAsync();

            return idAsistencia;
        }
        catch (PostgresException ex)
            when (ex.SqlState == "23505")
        {
            throw new InvalidOperationException(
                "El empleado ya tiene asistencia registrada para esa fecha.",
                ex);
        }
    }


        public async Task<bool> RegistrarSalida(
            long idAsistencia,
            RegistrarSalidaPersonalRequest request,
            int idAdministrador)
        {
            if (idAsistencia <= 0)
                throw new ArgumentException("La asistencia no es válida.");

            if (idAdministrador <= 0)
                throw new UnauthorizedAccessException();

            await using var connection =
                new NpgsqlConnection(_connectionString);

            await connection.OpenAsync();

            await using var command = new NpgsqlCommand(
                """
                UPDATE public.personal_asistencias
                SET
                    hora_salida = @hora_salida,
                    salida_registrada_por = @id_administrador,
                    fecha_registro_salida = CURRENT_TIMESTAMP
                WHERE id_asistencia_personal = @id_asistencia
                AND hora_salida IS NULL
                AND @hora_salida >= hora_entrada
                RETURNING id_asistencia_personal;
                """,
                connection
            );

            command.Parameters.AddWithValue(
                "hora_salida",
                NpgsqlDbType.Time,
                request.HoraSalida
            );

            command.Parameters.AddWithValue(
                "id_administrador",
                idAdministrador
            );

            command.Parameters.AddWithValue(
                "id_asistencia",
                idAsistencia
            );

            var resultado = await command.ExecuteScalarAsync();

            return resultado != null;
        }


public async Task<List<object>> ObtenerHistorial(
    int? idPersonal,
    DateOnly? fechaInicio,
    DateOnly? fechaFin)
    {
        if (idPersonal.HasValue && idPersonal.Value <= 0)
            throw new ArgumentException("El empleado no es válido.");

        if (fechaInicio.HasValue && fechaFin.HasValue &&
            fechaInicio.Value > fechaFin.Value)
            throw new ArgumentException(
                "La fecha inicial no puede ser posterior a la final.");

        await using var connection =
            new NpgsqlConnection(_connectionString);

        await connection.OpenAsync();

        await using var command = new NpgsqlCommand(
            """
            SELECT
                a.id_asistencia_personal,
                a.id_personal,
                p.nombre_completo,
                a.fecha,
                a.hora_entrada,
                a.hora_salida,
                a.registrado_por,
                a.salida_registrada_por,
                a.fecha_registro,
                a.fecha_registro_salida
            FROM public.personal_asistencias a
            INNER JOIN public.personal p
                ON p.id_personal = a.id_personal
            WHERE (@id_personal IS NULL
                OR a.id_personal = @id_personal)
            AND (@fecha_inicio IS NULL
                OR a.fecha >= @fecha_inicio)
            AND (@fecha_fin IS NULL
                OR a.fecha <= @fecha_fin)
            ORDER BY a.fecha DESC, a.hora_entrada DESC
            LIMIT 500;
            """,
            connection
        );

        command.Parameters.Add(
            "id_personal", NpgsqlDbType.Integer
        ).Value = (object?)idPersonal ?? DBNull.Value;

        command.Parameters.Add(
            "fecha_inicio", NpgsqlDbType.Date
        ).Value = (object?)fechaInicio ?? DBNull.Value;

        command.Parameters.Add(
            "fecha_fin", NpgsqlDbType.Date
        ).Value = (object?)fechaFin ?? DBNull.Value;

        await using var reader =
            await command.ExecuteReaderAsync();

        var historial = new List<object>();

        while (await reader.ReadAsync())
        {
            historial.Add(new
            {
                idAsistenciaPersonal = reader.GetInt64(0),
                idPersonal = reader.GetInt32(1),
                nombreCompleto = reader.GetString(2),
                fecha = reader.GetDateTime(3).ToString("yyyy-MM-dd"),
                horaEntrada = reader.GetTimeSpan(4).ToString(@"hh\:mm\:ss"),
                horaSalida = reader.IsDBNull(5)
                    ? null
                    : reader.GetTimeSpan(5).ToString(@"hh\:mm\:ss"),
                registradoPor = reader.GetInt32(6),
                salidaRegistradaPor = reader.IsDBNull(7)
                    ? (int?)null
                    : reader.GetInt32(7),
                fechaRegistro = reader.GetDateTime(8),
                fechaRegistroSalida = reader.IsDBNull(9)
                    ? (DateTime?)null
                    : reader.GetDateTime(9)
            });
        }

        return historial;
    }


}
