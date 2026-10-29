
using Npgsql;

namespace GymManagement.api.Services;

public class AdministradorService
{
    private readonly string _connectionString;

    public AdministradorService(IConfiguration configuration)
    {
        _connectionString =
            configuration.GetConnectionString("PostgreSQL")
            ?? throw new InvalidOperationException(
                "No existe la conexión PostgreSQL.");
    }

    public async Task<List<object>> ObtenerAdministradores(
        int idAdministrador)
    {
        if (idAdministrador <= 0)
            throw new UnauthorizedAccessException(
                "Administrador no autorizado.");

        var administradores = new List<object>();

        await using var connection =
            new NpgsqlConnection(_connectionString);

        await connection.OpenAsync();

        // Confirmar que quien consulta es un administrador activo.
        await using (var validarAdmin = new NpgsqlCommand(
            """
            SELECT 1
            FROM public.usuarios u
            INNER JOIN public.roles r
                ON r.id_rol = u.id_rol
            WHERE u.id_usuario = @admin
              AND u.estatus = 'Activo'
              AND r.nombre = 'Administrador';
            """, connection))
        {
            validarAdmin.Parameters.AddWithValue(
                "admin", idAdministrador);

            if (await validarAdmin.ExecuteScalarAsync() is null)
                throw new UnauthorizedAccessException(
                    "Administrador no autorizado.");
        }

        // Consultar administradores sin exponer contraseñas.
        await using var command = new NpgsqlCommand(
            """
            SELECT
                u.id_usuario,
                p.id_personal,
                p.nombre_completo,
                u.correo,
                p.telefono,
                p.horario,
                u.estatus,
                p.fecha_alta,
                p.fecha_baja
            FROM public.usuarios u
            INNER JOIN public.roles r
                ON r.id_rol = u.id_rol
            LEFT JOIN public.personal p
                ON p.id_usuario = u.id_usuario
            WHERE r.nombre = 'Administrador'
            ORDER BY u.id_usuario;
            """, connection);

        await using var reader =
            await command.ExecuteReaderAsync();

        while (await reader.ReadAsync())
        {
            administradores.Add(new
            {
                idUsuario = reader.GetInt32(0),
                idPersonal = reader.IsDBNull(1)
                    ? (int?)null : reader.GetInt32(1),
                nombreCompleto = reader.IsDBNull(2)
                    ? null : reader.GetString(2),
                correo = reader.GetString(3),
                telefono = reader.IsDBNull(4)
                    ? null : reader.GetString(4),
                horario = reader.IsDBNull(5)
                    ? null : reader.GetString(5),
                estatus = reader.GetString(6),
                fechaAlta = reader.IsDBNull(7)
                    ? (DateOnly?)null
                    : reader.GetFieldValue<DateOnly>(7),
                fechaBaja = reader.IsDBNull(8)
                    ? (DateOnly?)null
                    : reader.GetFieldValue<DateOnly>(8)
            });
        }

        return administradores;
    }

public async Task<object?> ObtenerAdministradorPorId(
    int idUsuario,
    int idAdministrador)
    {
        if (idUsuario <= 0)
            throw new ArgumentException(
                "ID de administrador inválido.");

        if (idAdministrador <= 0)
            throw new UnauthorizedAccessException(
                "Administrador no autorizado.");

        await using var connection =
            new NpgsqlConnection(_connectionString);

        await connection.OpenAsync();

        // Confirmar que quien consulta sigue siendo administrador activo.
        await using (var validarAdmin = new NpgsqlCommand(
            """
            SELECT 1
            FROM public.usuarios u
            INNER JOIN public.roles r
                ON r.id_rol = u.id_rol
            WHERE u.id_usuario = @admin
            AND u.estatus = 'Activo'
            AND r.nombre = 'Administrador';
            """, connection))
        {
            validarAdmin.Parameters.AddWithValue(
                "admin", idAdministrador);

            if (await validarAdmin.ExecuteScalarAsync() is null)
                throw new UnauthorizedAccessException(
                    "Administrador no autorizado.");
        }

        await using var command = new NpgsqlCommand(
            """
            SELECT
                u.id_usuario,
                p.id_personal,
                p.nombre_completo,
                u.correo,
                p.telefono,
                p.horario,
                u.estatus,
                p.fecha_alta,
                p.fecha_baja
            FROM public.usuarios u
            INNER JOIN public.roles r
                ON r.id_rol = u.id_rol
            LEFT JOIN public.personal p
                ON p.id_usuario = u.id_usuario
            WHERE r.nombre = 'Administrador'
            AND u.id_usuario = @idUsuario;
            """, connection);

        command.Parameters.AddWithValue(
            "idUsuario", idUsuario);

        await using var reader =
            await command.ExecuteReaderAsync();

        if (!await reader.ReadAsync())
            return null;

        return new
        {
            idUsuario = reader.GetInt32(0),
            idPersonal = reader.IsDBNull(1)
                ? (int?)null : reader.GetInt32(1),
            nombreCompleto = reader.IsDBNull(2)
                ? null : reader.GetString(2),
            correo = reader.GetString(3),
            telefono = reader.IsDBNull(4)
                ? null : reader.GetString(4),
            horario = reader.IsDBNull(5)
                ? null : reader.GetString(5),
            estatus = reader.GetString(6),
            fechaAlta = reader.IsDBNull(7)
                ? (DateOnly?)null
                : reader.GetFieldValue<DateOnly>(7),
            fechaBaja = reader.IsDBNull(8)
                ? (DateOnly?)null
                : reader.GetFieldValue<DateOnly>(8)
        };
    }

}
