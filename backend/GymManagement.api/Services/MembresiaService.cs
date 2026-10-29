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

    public async Task EditarMembresia(
    int idMembresia,
    GymManagement.api.Models.EditarMembresiaRequest request,
    int idAdministrador)
    {
        if (idMembresia <= 0)
            throw new ArgumentException("ID de membresía inválido.");

        var nombre = request.NombrePlan?.Trim();
        var descripcion = request.Descripcion?.Trim() ?? "";

        if (string.IsNullOrWhiteSpace(nombre))
            throw new ArgumentException("El nombre es obligatorio.");

        if (request.CostoMensual <= 0 || request.CostoAnualidad <= 0)
            throw new ArgumentException("Los precios deben ser mayores que cero.");

        var connectionString =
            _configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException("Falta la conexión PostgreSQL.");

        await using var connection = new NpgsqlConnection(connectionString);
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

        // Asociar administrador con la transacción para auditoría.
        await using (var audit = new NpgsqlCommand("""
            SELECT set_config('gymflow.usuario_actual', @admin, true);
            """, connection, transaction))
        {
            audit.Parameters.AddWithValue(
                "admin", idAdministrador.ToString());

            await audit.ExecuteScalarAsync();
        }

        // Actualizar membresía conservando su ID.
        await using (var command = new NpgsqlCommand("""
            UPDATE public.membresias
            SET
                nombre_plan = @nombre,
                descripcion = @descripcion,
                costo_mensual = @mensual,
                costo_anualidad = @anual
            WHERE id_membresia = @id;
            """, connection, transaction))
        {
            command.Parameters.AddWithValue("id", idMembresia);
            command.Parameters.AddWithValue("nombre", nombre!);
            command.Parameters.AddWithValue("descripcion", descripcion);
            command.Parameters.AddWithValue("mensual", request.CostoMensual);
            command.Parameters.AddWithValue("anual", request.CostoAnualidad);

            var filas = await command.ExecuteNonQueryAsync();

            if (filas == 0)
                throw new KeyNotFoundException(
                    "La membresía no existe.");
        }

        await transaction.CommitAsync();
    }

    public async Task CambiarEstadoMembresia(
    int idMembresia,
    bool? activo,
    int idAdministrador)
    {
        if (idMembresia <= 0)
            throw new ArgumentException("ID de membresía inválido.");

        if (!activo.HasValue)
            throw new ArgumentException(
                "El estado activo es obligatorio.");

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

        // Validar administrador activo.
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

        // Identificar al administrador en la transacción.
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

        // Desactivar o activar sin eliminar el plan.
        await using (var command = new NpgsqlCommand("""
            UPDATE public.membresias
            SET activo = @activo
            WHERE id_membresia = @id;
            """, connection, transaction))
        {
            command.Parameters.AddWithValue("id", idMembresia);
            command.Parameters.AddWithValue("activo", activo.Value);

            var filas = await command.ExecuteNonQueryAsync();

            if (filas == 0)
                throw new KeyNotFoundException(
                    "La membresía no existe.");
        }

        await transaction.CommitAsync();
    }
    public async Task<List<object>> ObtenerHistorialPrecios(
    int idMembresia,
    int idAdministrador)
    {
        if (idMembresia <= 0)
            throw new ArgumentException("ID de membresía inválido.");

        var connectionString =
            _configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException(
                "Falta la conexión PostgreSQL.");

        await using var connection = new NpgsqlConnection(connectionString);
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

        await using (var existe = new NpgsqlCommand("""
            SELECT 1
            FROM public.membresias
            WHERE id_membresia = @id;
            """, connection, transaction))
        {
            existe.Parameters.AddWithValue("id", idMembresia);

            if (await existe.ExecuteScalarAsync() is null)
                throw new KeyNotFoundException(
                    "La membresía no existe.");
        }

        var historial = new List<object>();

        await using (var command = new NpgsqlCommand("""
            SELECT
                id_historial,
                id_membresia,
                costo_mensual,
                costo_anualidad,
                registrado_en,
                id_usuario_app,
                origen
            FROM public.membresias_precios_historial
            WHERE id_membresia = @id
            ORDER BY registrado_en DESC, id_historial DESC;
            """, connection, transaction))
        {
            command.Parameters.AddWithValue("id", idMembresia);

            await using var reader = await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                historial.Add(new
                {
                    idHistorial = reader.GetInt64(0),
                    idMembresia = reader.GetInt32(1),
                    costoMensual = reader.GetDecimal(2),
                    costoAnualidad = reader.GetDecimal(3),
                    registradoEn = reader.GetDateTime(4),
                    idUsuarioApp = reader.IsDBNull(5)
                        ? (int?)null
                        : reader.GetInt32(5),
                    origen = reader.GetString(6)
                });
            }
        }

        await transaction.CommitAsync();

        return historial;
    }
}