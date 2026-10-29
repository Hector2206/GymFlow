
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

}
