
using Npgsql;
using GymManagement.api.Models;

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


public async Task<int> CrearAdministrador(
    CrearAdministradorRequest request,
    int idAdministrador)
    {
        var nombre = request.NombreCompleto?.Trim();
        var correo = request.Correo?.Trim().ToLowerInvariant();
        var telefono = request.Telefono?.Trim();
        var horario = request.Horario?.Trim();

        if (idAdministrador <= 0)
            throw new UnauthorizedAccessException(
                "Administrador no autorizado.");

        if (string.IsNullOrWhiteSpace(nombre) ||
            string.IsNullOrWhiteSpace(correo) ||
            string.IsNullOrWhiteSpace(telefono) ||
            string.IsNullOrWhiteSpace(horario) ||
            string.IsNullOrWhiteSpace(request.Password))
            throw new ArgumentException(
                "Nombre, correo, teléfono, horario y contraseña son obligatorios.");

        if (request.Password.Length < 8)
            throw new ArgumentException(
                "La contraseña debe tener al menos 8 caracteres.");

        if (request.Sueldo < 0)
            throw new ArgumentException(
                "El sueldo no puede ser negativo.");

        if (request.FechaContratacion == default ||
            request.FechaContratacion > DateOnly.FromDateTime(DateTime.Today))
            throw new ArgumentException(
                "La fecha de contratación no es válida.");

        if (nombre.Length > 200 ||
            correo.Length > 200 ||
            telefono.Length > 30 ||
            horario.Length > 100)
            throw new ArgumentException(
                "Uno de los campos supera la longitud permitida.");

        var passwordHash =
            BCrypt.Net.BCrypt.HashPassword(request.Password);

        await using var connection =
            new NpgsqlConnection(_connectionString);

        await connection.OpenAsync();

        await using var transaction =
            await connection.BeginTransactionAsync();

        // Comprobar que quien crea la cuenta sigue siendo administrador activo.
        await using (var validar = new NpgsqlCommand(
            """
            SELECT u.id_usuario
            FROM public.usuarios u
            INNER JOIN public.roles r ON r.id_rol = u.id_rol
            WHERE u.id_usuario = @admin
            AND u.estatus = 'Activo'
            AND r.nombre = 'Administrador'
            FOR SHARE OF u;
            """, connection, transaction))
        {
            validar.Parameters.AddWithValue("admin", idAdministrador);

            if (await validar.ExecuteScalarAsync() is null)
                throw new UnauthorizedAccessException(
                    "Administrador no autorizado.");
        }

        // Registrar al administrador responsable en la auditoría.
        await using (var audit = new NpgsqlCommand(
            """
            SELECT set_config('gymflow.usuario_actual', @admin, true);
            """, connection, transaction))
        {
            audit.Parameters.AddWithValue(
                "admin", idAdministrador.ToString());

            await audit.ExecuteScalarAsync();
        }

        // Consultar el rol Administrador existente.
        int idRol;

        await using (var rol = new NpgsqlCommand(
            """
            SELECT id_rol
            FROM public.roles
            WHERE nombre = 'Administrador';
            """, connection, transaction))
        {
            var resultado = await rol.ExecuteScalarAsync();

            if (resultado is null)
                throw new InvalidOperationException(
                    "No existe el rol Administrador.");

            idRol = Convert.ToInt32(resultado);
        }

        // Crear cuenta de acceso.
        int idUsuario;

        await using (var usuario = new NpgsqlCommand(
            """
            INSERT INTO public.usuarios
                (correo, contrasena_hash, id_rol, estatus)
            VALUES
                (@correo, @hash, @rol, 'Activo')
            RETURNING id_usuario;
            """, connection, transaction))
        {
            usuario.Parameters.AddWithValue("correo", correo!);
            usuario.Parameters.AddWithValue("hash", passwordHash);
            usuario.Parameters.AddWithValue("rol", idRol);

            try
            {
                idUsuario = Convert.ToInt32(
                    await usuario.ExecuteScalarAsync());
            }
            catch (PostgresException ex)
                when (ex.SqlState == PostgresErrorCodes.UniqueViolation)
            {
                throw new ArgumentException(
                    "Ya existe una cuenta registrada con ese correo.");
            }
        }

        // Crear expediente del administrador.
        int idPersonal;

        await using (var personal = new NpgsqlCommand(
            """
            INSERT INTO public.personal
            (
                id_usuario,
                nombre_completo,
                telefono,
                salario,
                dia_pago_salario,
                horario,
                fecha_alta
            )
            VALUES
            (
                @usuario,
                @nombre,
                @telefono,
                @salario,
                15,
                @horario,
                @fechaAlta
            )
            RETURNING id_personal;
            """, connection, transaction))
        {
            personal.Parameters.AddWithValue("usuario", idUsuario);
            personal.Parameters.AddWithValue("nombre", nombre!);
            personal.Parameters.AddWithValue("telefono", telefono!);
            personal.Parameters.AddWithValue("salario", request.Sueldo);
            personal.Parameters.AddWithValue("horario", horario!);
            personal.Parameters.AddWithValue(
                "fechaAlta",
                request.FechaContratacion.ToDateTime(TimeOnly.MinValue));

            idPersonal = Convert.ToInt32(
                await personal.ExecuteScalarAsync());
        }

        // Registrar historial del sueldo inicial.
        await using (var salario = new NpgsqlCommand(
            """
            INSERT INTO public.personal_salarios_historial
            (
                id_personal,
                monto,
                periodicidad,
                vigente_desde,
                motivo,
                registrado_por
            )
            VALUES
            (
                @personal,
                @monto,
                'Mensual',
                @fechaAlta,
                'Sueldo inicial',
                @admin
            );
            """, connection, transaction))
        {
            salario.Parameters.AddWithValue("personal", idPersonal);
            salario.Parameters.AddWithValue("monto", request.Sueldo);
            salario.Parameters.AddWithValue(
                "fechaAlta",
                request.FechaContratacion.ToDateTime(TimeOnly.MinValue));
            salario.Parameters.AddWithValue("admin", idAdministrador);

            await salario.ExecuteNonQueryAsync();
        }

        await transaction.CommitAsync();

        return idUsuario;
    }


public async Task<bool> EditarAdministrador(
    int idUsuario,
    EditarAdministradorRequest request,
    int idAdministrador)
    {
        if (idUsuario <= 0)
            throw new ArgumentException("ID de administrador inválido.");

        if (idAdministrador <= 0)
            throw new UnauthorizedAccessException(
                "Administrador no autorizado.");

        var nombre = request.NombreCompleto?.Trim();
        var correo = request.Correo?.Trim().ToLowerInvariant();
        var telefono = request.Telefono?.Trim();
        var horario = request.Horario?.Trim();

        if (string.IsNullOrWhiteSpace(nombre) ||
            string.IsNullOrWhiteSpace(correo) ||
            string.IsNullOrWhiteSpace(telefono) ||
            string.IsNullOrWhiteSpace(horario))
            throw new ArgumentException(
                "Nombre, correo, teléfono y horario son obligatorios.");

        if (nombre.Length > 200 ||
            correo.Length > 200 ||
            telefono.Length > 30 ||
            horario.Length > 100)
            throw new ArgumentException(
                "Uno de los campos supera la longitud permitida.");

        await using var connection =
            new NpgsqlConnection(_connectionString);

        await connection.OpenAsync();

        await using var transaction =
            await connection.BeginTransactionAsync();

        // Verificar que quien edita sea administrador activo.
        await using (var validar = new NpgsqlCommand(
            """
            SELECT u.id_usuario
            FROM public.usuarios u
            JOIN public.roles r ON r.id_rol = u.id_rol
            WHERE u.id_usuario = @admin
            AND u.estatus = 'Activo'
            AND r.nombre = 'Administrador'
            FOR SHARE OF u;
            """, connection, transaction))
        {
            validar.Parameters.AddWithValue("admin", idAdministrador);

            if (await validar.ExecuteScalarAsync() is null)
                throw new UnauthorizedAccessException(
                    "Administrador no autorizado.");
        }

        // Registrar responsable de la operación para auditoría.
        await using (var audit = new NpgsqlCommand(
            "SELECT set_config('gymflow.usuario_actual', @admin, true);",
            connection, transaction))
        {
            audit.Parameters.AddWithValue(
                "admin", idAdministrador.ToString());

            await audit.ExecuteScalarAsync();
        }

        // Bloquear el expediente para evitar modificaciones concurrentes.
        int idPersonal;

        await using (var buscar = new NpgsqlCommand(
            """
            SELECT p.id_personal
            FROM public.usuarios u
            JOIN public.roles r ON r.id_rol = u.id_rol
            JOIN public.personal p ON p.id_usuario = u.id_usuario
            WHERE u.id_usuario = @id
            AND r.nombre = 'Administrador'
            AND u.estatus = 'Activo'
            AND p.fecha_baja IS NULL
            FOR UPDATE OF p, u;
            """, connection, transaction))
        {
            buscar.Parameters.AddWithValue("id", idUsuario);

            var resultado = await buscar.ExecuteScalarAsync();

            if (resultado is null)
                return false;

            idPersonal = Convert.ToInt32(resultado);
        }

        // Actualizar el correo de acceso.
        await using (var usuario = new NpgsqlCommand(
            """
            UPDATE public.usuarios
            SET correo = @correo
            WHERE id_usuario = @id;
            """, connection, transaction))
        {
            usuario.Parameters.AddWithValue("correo", correo!);
            usuario.Parameters.AddWithValue("id", idUsuario);

            try
            {
                await usuario.ExecuteNonQueryAsync();
            }
            catch (PostgresException ex)
                when (ex.SqlState == PostgresErrorCodes.UniqueViolation)
            {
                throw new ArgumentException(
                    "Ya existe una cuenta registrada con ese correo.");
            }
        }

        // Actualizar datos personales sin modificar salario ni contraseña.
        await using (var personal = new NpgsqlCommand(
            """
            UPDATE public.personal
            SET nombre_completo = @nombre,
                telefono = @telefono,
                horario = @horario
            WHERE id_personal = @idPersonal;
            """, connection, transaction))
        {
            personal.Parameters.AddWithValue("nombre", nombre!);
            personal.Parameters.AddWithValue("telefono", telefono!);
            personal.Parameters.AddWithValue("horario", horario!);
            personal.Parameters.AddWithValue("idPersonal", idPersonal);

            await personal.ExecuteNonQueryAsync();
        }

        await transaction.CommitAsync();

        return true;
    }


public async Task<bool> DarDeBajaAdministrador(
    int idUsuario,
    DarBajaAdministradorRequest request,
    int idAdministrador)
    {
        if (idUsuario <= 0)
            throw new ArgumentException("ID de administrador inválido.");

        if (idAdministrador <= 0)
            throw new UnauthorizedAccessException(
                "Administrador no autorizado.");

        if (idUsuario == idAdministrador)
            throw new ArgumentException(
                "No puedes dar de baja tu propia cuenta.");

        var motivo = request.MotivoBaja?.Trim();

        if (string.IsNullOrWhiteSpace(motivo))
            throw new ArgumentException(
                "El motivo de baja es obligatorio.");

        if (request.FechaBaja == default ||
            request.FechaBaja > DateOnly.FromDateTime(DateTime.Today))
            throw new ArgumentException(
                "La fecha de baja no es válida.");

        await using var connection =
            new NpgsqlConnection(_connectionString);

        await connection.OpenAsync();

        await using var transaction =
            await connection.BeginTransactionAsync();

        // Serializar las bajas de administradores para impedir
        // que operaciones simultáneas desactiven al último.
        await using (var bloqueo = new NpgsqlCommand(
            """
            SELECT pg_advisory_xact_lock(724031, 1);
            """, connection, transaction))
        {
            await bloqueo.ExecuteNonQueryAsync();
        }

        // Verificar que el administrador responsable siga activo.
        await using (var validar = new NpgsqlCommand(
            """
            SELECT u.id_usuario
            FROM public.usuarios u
            JOIN public.roles r ON r.id_rol = u.id_rol
            WHERE u.id_usuario = @admin
            AND u.estatus = 'Activo'
            AND r.nombre = 'Administrador'
            FOR SHARE OF u;
            """, connection, transaction))
        {
            validar.Parameters.AddWithValue("admin", idAdministrador);

            if (await validar.ExecuteScalarAsync() is null)
                throw new UnauthorizedAccessException(
                    "Administrador no autorizado.");
        }

        // Bloquear la cuenta que se pretende desactivar.
        int idPersonal;

        await using (var buscar = new NpgsqlCommand(
            """
            SELECT p.id_personal
            FROM public.usuarios u
            JOIN public.roles r ON r.id_rol = u.id_rol
            JOIN public.personal p ON p.id_usuario = u.id_usuario
            WHERE u.id_usuario = @id
            AND r.nombre = 'Administrador'
            AND u.estatus = 'Activo'
            AND p.fecha_baja IS NULL
            FOR UPDATE OF u, p;
            """, connection, transaction))
        {
            buscar.Parameters.AddWithValue("id", idUsuario);

            var resultado = await buscar.ExecuteScalarAsync();

            if (resultado is null)
                return false;

            idPersonal = Convert.ToInt32(resultado);
        }

        // Comprobar que existen al menos dos administradores activos.
        await using (var contar = new NpgsqlCommand(
            """
            SELECT COUNT(*)
            FROM public.usuarios u
            JOIN public.roles r ON r.id_rol = u.id_rol
            JOIN public.personal p ON p.id_usuario = u.id_usuario
            WHERE r.nombre = 'Administrador'
            AND u.estatus = 'Activo'
            AND p.fecha_baja IS NULL;
            """, connection, transaction))
        {
            var activos = Convert.ToInt64(
                await contar.ExecuteScalarAsync());

            if (activos <= 1)
                throw new InvalidOperationException(
                    "No se puede desactivar al último administrador activo.");
        }

        // Registrar el responsable en la auditoría.
        await using (var audit = new NpgsqlCommand(
            "SELECT set_config('gymflow.usuario_actual', @admin, true);",
            connection, transaction))
        {
            audit.Parameters.AddWithValue(
                "admin", idAdministrador.ToString());

            await audit.ExecuteScalarAsync();
        }

        // Desactivar el acceso sin eliminar al usuario.
        await using (var usuario = new NpgsqlCommand(
            """
            UPDATE public.usuarios
            SET estatus = 'Inactivo'
            WHERE id_usuario = @id;
            """, connection, transaction))
        {
            usuario.Parameters.AddWithValue("id", idUsuario);
            await usuario.ExecuteNonQueryAsync();
        }

        // Registrar la baja en su expediente laboral.
        await using (var personal = new NpgsqlCommand(
            """
            UPDATE public.personal
            SET fecha_baja = @fecha,
                motivo_baja = @motivo
            WHERE id_personal = @personal;
            """, connection, transaction))
        {
            personal.Parameters.AddWithValue("fecha", request.FechaBaja);
            personal.Parameters.AddWithValue("motivo", motivo!);
            personal.Parameters.AddWithValue("personal", idPersonal);

            await personal.ExecuteNonQueryAsync();
        }

        await transaction.CommitAsync();

        return true;
    }

}
