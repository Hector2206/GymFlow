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

    public async Task<int> CrearMembresia(
    GymManagement.api.Models.CrearMembresiaRequest request,
    int idAdministrador)
    {
        var nombre = request.NombrePlan?.Trim();
        var descripcion = request.Descripcion?.Trim() ?? "";

        if (string.IsNullOrWhiteSpace(nombre))
            throw new ArgumentException(
                "El nombre de la membresía es obligatorio.");

        if (request.CostoMensual <= 0 ||
            request.CostoAnualidad <= 0)
            throw new ArgumentException(
                "Los precios deben ser mayores que cero.");

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

        // Verificar administrador activo.
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

        // Identificar al administrador para el trigger.
        await using (var audit = new NpgsqlCommand("""
            SELECT set_config(
                'gymflow.usuario_actual',
                @admin,
                true
            );
            """, connection, transaction))
        {
            audit.Parameters.AddWithValue(
                "admin", idAdministrador.ToString());

            await audit.ExecuteScalarAsync();
        }

        // Crear la membresía.
        int idMembresia;

        await using (var command = new NpgsqlCommand("""
            INSERT INTO public.membresias
            (
                nombre_plan,
                costo_mensual,
                costo_anualidad,
                descripcion,
                activo
            )
            VALUES
            (
                @nombre,
                @mensual,
                @anual,
                @descripcion,
                TRUE
            )
            RETURNING id_membresia;
            """, connection, transaction))
        {
            command.Parameters.AddWithValue("nombre", nombre!);
            command.Parameters.AddWithValue(
                "mensual", request.CostoMensual);
            command.Parameters.AddWithValue(
                "anual", request.CostoAnualidad);
            command.Parameters.AddWithValue(
                "descripcion", descripcion);

            idMembresia = Convert.ToInt32(
                await command.ExecuteScalarAsync());
        }

        await transaction.CommitAsync();

        return idMembresia;
    }
}