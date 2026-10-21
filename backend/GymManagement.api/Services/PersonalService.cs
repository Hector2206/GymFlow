
using Npgsql;
using GymManagement.api.Models;

namespace GymManagement.api.Services;

public class PersonalService
{
    private readonly IConfiguration _configuration;

    public PersonalService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public async Task EditarPersonal(int idPersonal, EditarPersonalRequest request, int idAdministrador)
    {
        if (idPersonal <= 0)
            throw new ArgumentException("ID de empleado inválido.");
        request.NormalizarYValidar();

        var connectionString = _configuration.GetConnectionString("PostgreSQL");
        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException("Falta la conexión PostgreSQL.");

        await using var connection = new NpgsqlConnection(connectionString);
        await connection.OpenAsync();
        await using var transaction = await connection.BeginTransactionAsync();

        await using (var admin = new NpgsqlCommand("""
            SELECT u.id_usuario
            FROM usuarios u JOIN roles r ON r.id_rol = u.id_rol
            WHERE u.id_usuario = @admin AND u.estatus = 'Activo'
              AND r.nombre = 'Administrador'
            FOR SHARE OF u;
            """, connection, transaction))
        {
            admin.Parameters.AddWithValue("admin", idAdministrador);
            if (await admin.ExecuteScalarAsync() is null)
                throw new UnauthorizedAccessException("Administrador no autorizado.");
        }

        int idUsuario;
        await using (var select = new NpgsqlCommand("""
            SELECT p.id_usuario, u.estatus, p.fecha_baja
            FROM personal p
            JOIN usuarios u ON u.id_usuario = p.id_usuario
            JOIN roles r ON r.id_rol = u.id_rol
            WHERE p.id_personal = @id AND r.nombre IN ('Entrenador', 'Recepcionista')
            FOR UPDATE OF p, u;
            """, connection, transaction))
        {
            select.Parameters.AddWithValue("id", idPersonal);
            await using var reader = await select.ExecuteReaderAsync();
            if (!await reader.ReadAsync())
                throw new KeyNotFoundException("Empleado no encontrado.");
            if (reader.GetString(1) != "Activo" || !reader.IsDBNull(2))
                throw new InvalidOperationException("No se puede editar un empleado dado de baja.");
            idUsuario = reader.GetInt32(0);
        }

        await using (var audit = new NpgsqlCommand(
            "SELECT set_config('gymflow.usuario_actual', @admin, true)", connection, transaction))
        {
            audit.Parameters.AddWithValue("admin", idAdministrador.ToString());
            await audit.ExecuteScalarAsync();
        }

        // La restricción UNIQUE resuelve también correos duplicados concurrentes.
        await using (var usuario = new NpgsqlCommand("""
            UPDATE usuarios SET correo = @correo WHERE id_usuario = @id;
            """, connection, transaction))
        {
            usuario.Parameters.AddWithValue("correo", request.Correo);
            usuario.Parameters.AddWithValue("id", idUsuario);
            await usuario.ExecuteNonQueryAsync();
        }

        await using (var personal = new NpgsqlCommand("""
            UPDATE personal
            SET nombre_completo = @nombre, telefono = @telefono,
                horario = @horario, fecha_actualizacion = CURRENT_TIMESTAMP
            WHERE id_personal = @id;
            """, connection, transaction))
        {
            personal.Parameters.AddWithValue("nombre", request.NombreCompleto);
            personal.Parameters.AddWithValue("telefono", request.Telefono);
            personal.Parameters.AddWithValue("horario", request.Horario);
            personal.Parameters.AddWithValue("id", idPersonal);
            await personal.ExecuteNonQueryAsync();
        }

        // Dispose revierte la transacción ante cualquier error previo al commit.
        await transaction.CommitAsync();
    }

    public async Task<int> CrearPersonal(
        CrearPersonalRequest request,
        int idAdministrador)
    {
        var nombre = request.NombreCompleto?.Trim();
        var correo = request.Correo?.Trim().ToLowerInvariant();
        var telefono = request.Telefono?.Trim();
        var puesto = request.Puesto?.Trim();

        if (string.IsNullOrWhiteSpace(nombre) ||
            string.IsNullOrWhiteSpace(correo) ||
            string.IsNullOrWhiteSpace(telefono) ||
            string.IsNullOrWhiteSpace(request.Password))
        {
            throw new ArgumentException(
                "Nombre, correo, teléfono y contraseña son obligatorios.");
        }

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

        if (puesto != "Entrenador" &&
            puesto != "Recepcionista")
            throw new ArgumentException(
                "Solo se pueden registrar entrenadores y recepcionistas.");

        var connectionString =
            _configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException(
                "Falta la conexión PostgreSQL.");

        var passwordHash =
            BCrypt.Net.BCrypt.HashPassword(request.Password);

        await using var connection =
            new NpgsqlConnection(connectionString);

        await connection.OpenAsync();

        await using var transaction =
            await connection.BeginTransactionAsync();

        try
        {
            // Registrar administrador para la auditoría
            await using (var audit = new NpgsqlCommand(
                "SELECT set_config('gymflow.usuario_actual', @id, true)",
                connection, transaction))
            {
                audit.Parameters.AddWithValue(
                    "id", idAdministrador.ToString());

                await audit.ExecuteScalarAsync();
            }

            // Verificar que el administrador sigue activo
            await using (var command = new NpgsqlCommand(
                """
                SELECT EXISTS (
                    SELECT 1
                    FROM usuarios u
                    INNER JOIN roles r ON r.id_rol = u.id_rol
                    WHERE u.id_usuario = @idAdministrador
                      AND u.estatus = 'Activo'
                      AND r.nombre = 'Administrador'
                );
                """, connection, transaction))
            {
                command.Parameters.AddWithValue(
                    "idAdministrador", idAdministrador);

                var autorizado = (bool)(
                    await command.ExecuteScalarAsync() ?? false
                );

                if (!autorizado)
                    throw new UnauthorizedAccessException(
                        "Administrador inactivo o sin permisos.");
            }

            // Buscar el rol existente
            int idRol;

            await using (var command = new NpgsqlCommand(
                "SELECT id_rol FROM roles WHERE nombre = @puesto",
                connection, transaction))
            {
                command.Parameters.AddWithValue("puesto", puesto!);

                var resultado = await command.ExecuteScalarAsync();

                if (resultado == null)
                    throw new ArgumentException("El rol no existe.");

                idRol = Convert.ToInt32(resultado);
            }

            // Crear usuario
            int idUsuario;

            await using (var command = new NpgsqlCommand(
                """
                INSERT INTO usuarios
                    (correo, contrasena_hash, id_rol, estatus)
                VALUES
                    (@correo, @passwordHash, @idRol, 'Activo')
                RETURNING id_usuario;
                """, connection, transaction))
            {
                command.Parameters.AddWithValue("correo", correo!);
                command.Parameters.AddWithValue("passwordHash", passwordHash);
                command.Parameters.AddWithValue("idRol", idRol);

                idUsuario = Convert.ToInt32(
                    await command.ExecuteScalarAsync());
            }

            // Crear expediente laboral
            int idPersonal;

            await using (var command = new NpgsqlCommand(
                """
                INSERT INTO personal
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
                    @idUsuario,
                    @nombre,
                    @telefono,
                    @salario,
                    15,
                    'Pendiente de asignar',
                    @fechaAlta
                )
                RETURNING id_personal;
                """, connection, transaction))
            {
                command.Parameters.AddWithValue("idUsuario", idUsuario);
                command.Parameters.AddWithValue("nombre", nombre!);
                command.Parameters.AddWithValue("telefono", telefono!);
                command.Parameters.AddWithValue("salario", request.Sueldo);
                command.Parameters.AddWithValue(
                    "fechaAlta",
                    request.FechaContratacion.ToDateTime(TimeOnly.MinValue));

                idPersonal = Convert.ToInt32(
                    await command.ExecuteScalarAsync());
            }

            // Registrar sueldo mensual inicial
            await using (var command = new NpgsqlCommand(
                """
                INSERT INTO personal_salarios_historial
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
                    @idPersonal,
                    @monto,
                    'Mensual',
                    @fechaAlta,
                    'Sueldo inicial',
                    @idAdministrador
                );
                """, connection, transaction))
            {
                command.Parameters.AddWithValue("idPersonal", idPersonal);
                command.Parameters.AddWithValue("monto", request.Sueldo);
                command.Parameters.AddWithValue(
                    "fechaAlta",
                    request.FechaContratacion.ToDateTime(TimeOnly.MinValue));
                command.Parameters.AddWithValue(
                    "idAdministrador", idAdministrador);

                await command.ExecuteNonQueryAsync();
            }

            await transaction.CommitAsync();

            return idPersonal;
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    public async Task<List<object>> ObtenerPersonal()
    {
        var connectionString =
            _configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException(
                "Falta la conexión PostgreSQL.");

        var empleados = new List<object>();

        await using var connection =
            new NpgsqlConnection(connectionString);

        await connection.OpenAsync();

        const string sql = """
            SELECT
                p.id_personal,
                p.nombre_completo,
                u.correo,
                p.telefono,
                r.nombre AS puesto,
                p.salario,
                p.fecha_alta,
                p.fecha_baja,
                u.estatus,
                p.horario
            FROM personal p
            INNER JOIN usuarios u
                ON u.id_usuario = p.id_usuario
            INNER JOIN roles r
                ON r.id_rol = u.id_rol
            WHERE r.nombre IN (
                'Entrenador',
                'Recepcionista'
            )
            ORDER BY p.id_personal;
            """;

        await using var command =
            new NpgsqlCommand(sql, connection);

        await using var reader =
            await command.ExecuteReaderAsync();

        while (await reader.ReadAsync())
        {
            empleados.Add(new
            {
                idPersonal = reader.GetInt32(0),
                nombreCompleto = reader.GetString(1),
                correo = reader.GetString(2),
                telefono = reader.GetString(3),
                puesto = reader.GetString(4),
                salario = reader.GetDecimal(5),
                fechaContratacion = reader.GetDateTime(6)
                    .ToString("yyyy-MM-dd"),
                fechaBaja = reader.IsDBNull(7)
                    ? null
                    : reader.GetDateTime(7)
                        .ToString("yyyy-MM-dd"),
                estatus = reader.GetString(8),
                horario = reader.GetString(9)
            });
        }

        return empleados;
    }


public async Task<int> DarDeBajaPersonal(
    int idPersonal,
    string motivo,
    int idAdministrador)
{
    if (idPersonal <= 0)
        throw new ArgumentException("ID de empleado inválido.");

    if (string.IsNullOrWhiteSpace(motivo))
        throw new ArgumentException("El motivo es obligatorio.");

    var connectionString =
        _configuration.GetConnectionString("PostgreSQL")
        ?? throw new InvalidOperationException(
            "Falta configurar PostgreSQL.");

    await using var connection =
        new NpgsqlConnection(connectionString);

    await connection.OpenAsync();

    await using var transaction =
        await connection.BeginTransactionAsync();

    try
    {
        // Identificar al administrador que realiza la baja.
        await using (var auditCommand = new NpgsqlCommand(
            "SELECT set_config('gymflow.usuario_actual', @admin, true)",
            connection,
            transaction))
        {
            auditCommand.Parameters.AddWithValue(
                "admin", idAdministrador.ToString());

            await auditCommand.ExecuteNonQueryAsync();
        }

        // Confirmar que el administrador continúa activo.
        await using (var adminCommand = new NpgsqlCommand("""
            SELECT 1
            FROM usuarios u
            JOIN roles r ON r.id_rol = u.id_rol
            WHERE u.id_usuario = @admin
              AND u.estatus = 'Activo'
              AND r.nombre = 'Administrador';
            """, connection, transaction))
        {
            adminCommand.Parameters.AddWithValue("admin", idAdministrador);

            if (await adminCommand.ExecuteScalarAsync() is null)
                throw new UnauthorizedAccessException(
                    "Administrador no autorizado.");
        }

        int idUsuario;
        string puesto;

        // Bloquear el empleado durante la operación.
        await using (var selectCommand = new NpgsqlCommand("""
            SELECT p.id_usuario, r.nombre
            FROM personal p
            JOIN usuarios u ON u.id_usuario = p.id_usuario
            JOIN roles r ON r.id_rol = u.id_rol
            WHERE p.id_personal = @idPersonal
              AND u.estatus = 'Activo'
              AND r.nombre IN ('Entrenador', 'Recepcionista')
            FOR UPDATE OF p, u;
            """, connection, transaction))
        {
            selectCommand.Parameters.AddWithValue(
                "idPersonal", idPersonal);

            await using var reader =
                await selectCommand.ExecuteReaderAsync();

            if (!await reader.ReadAsync())
                throw new ArgumentException(
                    "Empleado inexistente o ya inactivo.");

            idUsuario = reader.GetInt32(0);
            puesto = reader.GetString(1);
        }

        int clientesDesasignados = 0;

        // Si es entrenador, desasignar sus clientes.
        if (puesto == "Entrenador")
        {
            await using var clientsCommand = new NpgsqlCommand("""
                UPDATE clientes
                SET id_entrenador = NULL
                WHERE id_entrenador = @idPersonal;
                """, connection, transaction);

            clientsCommand.Parameters.AddWithValue(
                "idPersonal", idPersonal);

            clientesDesasignados =
                await clientsCommand.ExecuteNonQueryAsync();
        }

        // Registrar su baja laboral.
        await using (var personalCommand = new NpgsqlCommand("""
            UPDATE personal
            SET fecha_baja = CURRENT_DATE,
                motivo_baja = @motivo,
                fecha_actualizacion = CURRENT_TIMESTAMP
            WHERE id_personal = @idPersonal;
            """, connection, transaction))
        {
            personalCommand.Parameters.AddWithValue(
                "motivo", motivo.Trim());

            personalCommand.Parameters.AddWithValue(
                "idPersonal", idPersonal);

            await personalCommand.ExecuteNonQueryAsync();
        }

        // Desactivar su acceso al sistema.
        await using (var usuarioCommand = new NpgsqlCommand("""
            UPDATE usuarios
            SET estatus = 'Inactivo'
            WHERE id_usuario = @idUsuario;
            """, connection, transaction))
        {
            usuarioCommand.Parameters.AddWithValue(
                "idUsuario", idUsuario);

            await usuarioCommand.ExecuteNonQueryAsync();
        }

        await transaction.CommitAsync();

        return clientesDesasignados;
    }
    catch
    {
        await transaction.RollbackAsync();
        throw;
    }
}
        public async Task<List<SalarioPersonalResponse>> ObtenerHistorialSalarios(
        int idPersonal,
        int idAdministrador)
    {
        if (idPersonal <= 0)
            throw new ArgumentException("ID de empleado inválido.");

        var connectionString =
            _configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException("Falta la conexión PostgreSQL.");

        await using var connection = new NpgsqlConnection(connectionString);
        await connection.OpenAsync();

        // Confirmar permisos actuales, además del rol incluido en el JWT.
        await using (var admin = new NpgsqlCommand("""
            SELECT EXISTS (
                SELECT 1
                FROM usuarios u
                JOIN roles r ON r.id_rol = u.id_rol
                WHERE u.id_usuario = @admin
                AND u.estatus = 'Activo'
                AND r.nombre = 'Administrador'
            );
            """, connection))
        {
            admin.Parameters.AddWithValue("admin", idAdministrador);

            if (await admin.ExecuteScalarAsync() is not true)
                throw new UnauthorizedAccessException(
                    "Administrador no autorizado.");
        }

        // También permitir consultar empleados dados de baja.
        await using (var empleado = new NpgsqlCommand("""
            SELECT EXISTS (
                SELECT 1
                FROM personal p
                JOIN usuarios u ON u.id_usuario = p.id_usuario
                JOIN roles r ON r.id_rol = u.id_rol
                WHERE p.id_personal = @id
                AND r.nombre IN ('Entrenador', 'Recepcionista')
            );
            """, connection))
        {
            empleado.Parameters.AddWithValue("id", idPersonal);

            if (await empleado.ExecuteScalarAsync() is not true)
                throw new KeyNotFoundException("Empleado no encontrado.");
        }

        await using var command = new NpgsqlCommand("""
            SELECT id_salario,
                id_personal,
                monto,
                periodicidad,
                vigente_desde,
                vigente_hasta,
                motivo,
                registrado_por,
                creado_en
            FROM personal_salarios_historial
            WHERE id_personal = @id
            ORDER BY vigente_desde DESC, id_salario DESC;
            """, connection);

        command.Parameters.AddWithValue("id", idPersonal);

        var historial = new List<SalarioPersonalResponse>();

        await using var reader = await command.ExecuteReaderAsync();

        while (await reader.ReadAsync())
        {
            historial.Add(new SalarioPersonalResponse
            {
                IdSalario = reader.GetInt64(0),
                IdPersonal = reader.GetInt32(1),
                Monto = reader.GetDecimal(2),
                Periodicidad = reader.GetString(3),
                VigenteDesde = reader.GetFieldValue<DateOnly>(4),
                VigenteHasta = reader.IsDBNull(5)
                    ? null
                    : reader.GetFieldValue<DateOnly>(5),
                Motivo = reader.IsDBNull(6)
                    ? null
                    : reader.GetString(6),
                RegistradoPor = reader.IsDBNull(7)
                    ? null
                    : reader.GetInt32(7),
                CreadoEn = reader.GetDateTime(8)
            });
        }

        return historial;
    }
}



