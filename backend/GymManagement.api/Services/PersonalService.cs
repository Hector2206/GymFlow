
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

}
