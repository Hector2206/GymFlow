using Npgsql;

namespace GymManagement.api.Services;

public class DashboardService
{
    private readonly IConfiguration _configuration;

    public DashboardService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public async Task<long> ObtenerTotalClientes(int idAdministrador)
    {
        var connectionString =
            _configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException(
                "Falta la conexión PostgreSQL.");

        await using var connection =
            new NpgsqlConnection(connectionString);

        await connection.OpenAsync();

        await using var transaction =
            await connection.BeginTransactionAsync();

        // Verificar permisos actuales y mantener el bloqueo
        // hasta terminar la consulta.
        await using (var admin = new NpgsqlCommand("""
            SELECT u.id_usuario
            FROM public.usuarios u
            JOIN public.roles r ON r.id_rol = u.id_rol
            WHERE u.id_usuario = @admin
              AND u.estatus = 'Activo'
              AND r.nombre = 'Administrador'
            FOR SHARE OF u;
            """, connection, transaction))
        {
            admin.Parameters.AddWithValue(
                "admin", idAdministrador);

            if (await admin.ExecuteScalarAsync() is null)
                throw new UnauthorizedAccessException(
                    "Administrador no autorizado.");
        }

        await using var command = new NpgsqlCommand("""
            SELECT total_clientes
            FROM public.vw_admin_total_clientes;
            """, connection, transaction);

        var resultado = await command.ExecuteScalarAsync();

        if (resultado is not long total)
            throw new InvalidOperationException(
                "No se pudo obtener el total de clientes.");

        await transaction.CommitAsync();

        return total;
    }

    public async Task<long> ObtenerMembresiasActivas(int idAdministrador)
    {
        var connectionString =
            _configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException(
                "Falta la conexión PostgreSQL.");

        await using var connection =
            new NpgsqlConnection(connectionString);

        await connection.OpenAsync();

        await using var transaction =
            await connection.BeginTransactionAsync();

        await using (var admin = new NpgsqlCommand("""
            SELECT u.id_usuario
            FROM public.usuarios u
            JOIN public.roles r ON r.id_rol = u.id_rol
            WHERE u.id_usuario = @admin
            AND u.estatus = 'Activo'
            AND r.nombre = 'Administrador'
            FOR SHARE OF u;
            """, connection, transaction))
        {
            admin.Parameters.AddWithValue("admin", idAdministrador);

            if (await admin.ExecuteScalarAsync() is null)
                throw new UnauthorizedAccessException(
                    "Administrador no autorizado.");
        }

        await using var command = new NpgsqlCommand("""
            SELECT membresias_activas
            FROM public.vw_admin_membresias_activas;
            """, connection, transaction);

        var resultado = await command.ExecuteScalarAsync();

        if (resultado is not long total)
            throw new InvalidOperationException(
                "No se pudo obtener el total de membresías activas.");

        await transaction.CommitAsync();

        return total;
    }

    public async Task<long> ObtenerAsistenciasDia(int idAdministrador)
    {
        var connectionString =
            _configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException(
                "Falta la conexión PostgreSQL.");

        await using var connection =
            new NpgsqlConnection(connectionString);

        await connection.OpenAsync();

        await using var transaction =
            await connection.BeginTransactionAsync();

        await using (var admin = new NpgsqlCommand("""
            SELECT u.id_usuario
            FROM public.usuarios u
            JOIN public.roles r ON r.id_rol = u.id_rol
            WHERE u.id_usuario = @admin
            AND u.estatus = 'Activo'
            AND r.nombre = 'Administrador'
            FOR SHARE OF u;
            """, connection, transaction))
        {
            admin.Parameters.AddWithValue("admin", idAdministrador);

            if (await admin.ExecuteScalarAsync() is null)
                throw new UnauthorizedAccessException(
                    "Administrador no autorizado.");
        }

        await using var command = new NpgsqlCommand("""
            SELECT asistencias_dia
            FROM public.vw_admin_asistencias_dia;
            """, connection, transaction);

        var resultado = await command.ExecuteScalarAsync();

        if (resultado is not long total)
            throw new InvalidOperationException(
                "No se pudo obtener el total de asistencias del día.");

        await transaction.CommitAsync();

        return total;
    }
}