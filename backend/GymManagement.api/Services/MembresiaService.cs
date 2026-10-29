using Npgsql;

namespace GymManagement.api.Services;

public class MembresiaService
{
    private readonly IConfiguration _configuration;

    public MembresiaService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public async Task<List<object>> ObtenerMembresias(int idAdministrador)
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

        // Verificar administrador activo
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

        var membresias = new List<object>();

        await using (var command = new NpgsqlCommand("""
            SELECT
                id_membresia,
                nombre_plan,
                costo_mensual,
                costo_anualidad,
                descripcion,
                activo
            FROM public.membresias
            ORDER BY id_membresia;
            """, connection, transaction))
        {
            await using var reader = await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                membresias.Add(new
                {
                    idMembresia = reader.GetInt32(0),
                    nombrePlan = reader.GetString(1),
                    costoMensual = reader.GetDecimal(2),
                    costoAnualidad = reader.GetDecimal(3),
                    descripcion = reader.GetString(4),
                    activo = reader.GetBoolean(5)
                });
            }
        }

        await transaction.CommitAsync();

        return membresias;
    }

    public async Task<List<object>> ObtenerMembresiasActivas()
    {
        var connectionString =
            _configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException(
                "Falta la conexión PostgreSQL.");

        await using var connection =
            new NpgsqlConnection(connectionString);

        await connection.OpenAsync();

        var membresias = new List<object>();

        await using var command = new NpgsqlCommand("""
            SELECT
                id_membresia,
                nombre_plan,
                costo_mensual,
                costo_anualidad,
                descripcion,
                activo
            FROM public.membresias
            WHERE activo = TRUE
            ORDER BY id_membresia;
            """, connection);

        await using var reader = await command.ExecuteReaderAsync();

        while (await reader.ReadAsync())
        {
            membresias.Add(new
            {
                idMembresia = reader.GetInt32(0),
                nombrePlan = reader.GetString(1),
                costoMensual = reader.GetDecimal(2),
                costoAnualidad = reader.GetDecimal(3),
                descripcion = reader.GetString(4),
                activo = reader.GetBoolean(5)
            });
        }

        return membresias;
    }
}