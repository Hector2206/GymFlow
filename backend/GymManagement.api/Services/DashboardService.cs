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

    public async Task<long> ObtenerPagosRegistrados(int idAdministrador)
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
            SELECT pagos_registrados
            FROM public.vw_admin_pagos_registrados;
            """, connection, transaction);

        var resultado = await command.ExecuteScalarAsync();

        if (resultado is not long total)
            throw new InvalidOperationException(
                "No se pudo obtener el total de pagos registrados.");

        await transaction.CommitAsync();

        return total;
    }

    public async Task<decimal> ObtenerIngresosPeriodo(
    int idAdministrador,
    DateOnly desde,
    DateOnly hasta)
    {
        if (desde == default || hasta == default)
            throw new ArgumentException(
                "Las fechas del periodo son obligatorias.");

        if (hasta < desde)
            throw new ArgumentException(
                "La fecha final no puede ser anterior a la inicial.");

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
            SELECT public.fn_admin_ingresos_periodo(@desde, @hasta);
            """, connection, transaction);

        command.Parameters.AddWithValue(
            "desde", NpgsqlTypes.NpgsqlDbType.Date, desde);

        command.Parameters.AddWithValue(
            "hasta", NpgsqlTypes.NpgsqlDbType.Date, hasta);

        var resultado = await command.ExecuteScalarAsync();

        if (resultado is not decimal total)
            throw new InvalidOperationException(
                "No se pudieron obtener los ingresos del periodo.");

        await transaction.CommitAsync();

        return total;
    }

    // ==========================================
    // VALIDAR ADMINISTRADOR ACTIVO
    // ==========================================

    private static async Task ValidarAdminConsulta(
        NpgsqlConnection connection,
        NpgsqlTransaction transaction,
        int idAdministrador)
    {
        await using var command = new NpgsqlCommand("""
            SELECT u.id_usuario
            FROM public.usuarios u
            INNER JOIN public.roles r
                ON r.id_rol = u.id_rol
            WHERE u.id_usuario = @admin
              AND u.estatus = 'Activo'
              AND r.nombre = 'Administrador'
            FOR SHARE OF u;
            """, connection, transaction);

        command.Parameters.AddWithValue("admin", idAdministrador);

        if (await command.ExecuteScalarAsync() is null)
        {
            throw new UnauthorizedAccessException(
                "Administrador no autorizado.");
        }
    }

    // ==========================================
    // CONSULTAR ASISTENCIAS APROBADAS DE HOY
    // ==========================================

    public async Task<List<object>> ObtenerDetalleAsistenciasDia(
        int idAdministrador,
        int pagina,
        int limite)
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

        await ValidarAdminConsulta(
            connection, transaction, idAdministrador);

        var resultados = new List<object>();

        // Mantiene el mismo criterio del indicador actual:
        // solamente accesos aprobados del día actual.
        await using (var command = new NpgsqlCommand("""
            SELECT
                a.id_asistencia_registro,
                a.id_cliente,
                c.nombre_completo,
                a.fecha_hora,
                a.estado_acceso,
                a.origen_registro
            FROM public.asistencias a
            INNER JOIN public.clientes c
                ON c.id_cliente = a.id_cliente
            WHERE a.estado_acceso = 'Aprobado'
              AND a.fecha_hora >= CURRENT_DATE
              AND a.fecha_hora < CURRENT_DATE + INTERVAL '1 day'
            ORDER BY
                a.fecha_hora DESC,
                a.id_asistencia_registro DESC
            LIMIT @limite OFFSET @offset;
            """, connection, transaction))
        {
            command.Parameters.AddWithValue("limite", limite);
            command.Parameters.AddWithValue(
                "offset", (pagina - 1) * limite);

            await using var reader =
                await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                resultados.Add(new
                {
                    idAsistencia = reader.GetInt32(0),
                    idCliente = reader.GetInt32(1),
                    nombreCliente = reader.GetString(2),
                    fechaHora = reader.GetDateTime(3),
                    estadoAcceso = reader.GetString(4),
                    origenRegistro = reader.GetString(5)
                });
            }
        }

        await transaction.CommitAsync();

        return resultados;
    }

    // ==========================================
    // CONSULTAR HISTORIAL GENERAL DE PAGOS
    // ==========================================

    public async Task<List<object>> ObtenerDetallePagos(
        int idAdministrador,
        int pagina,
        int limite)
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

        await ValidarAdminConsulta(
            connection, transaction, idAdministrador);

        var resultados = new List<object>();

        await using (var command = new NpgsqlCommand("""
            SELECT
                h.id_pago,
                h.id_cliente,
                c.nombre_completo,
                h.monto_pagado,
                h.tipo_pago,
                h.fecha_transaccion,
                h.concepto
            FROM public.historial_pagos h
            INNER JOIN public.clientes c
                ON c.id_cliente = h.id_cliente
            ORDER BY
                h.fecha_transaccion DESC,
                h.id_pago DESC
            LIMIT @limite OFFSET @offset;
            """, connection, transaction))
        {
            command.Parameters.AddWithValue("limite", limite);
            command.Parameters.AddWithValue(
                "offset", (pagina - 1) * limite);

            await using var reader =
                await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                resultados.Add(new
                {
                    idPago = reader.GetInt32(0),
                    idCliente = reader.GetInt32(1),
                    nombreCliente = reader.GetString(2),
                    monto = reader.GetDecimal(3),
                    tipoPago = reader.GetString(4),
                    fechaTransaccion = reader.GetDateTime(5),
                    concepto = reader.IsDBNull(6)
                        ? null
                        : reader.GetString(6)
                });
            }
        }

        await transaction.CommitAsync();

        return resultados;
    }

}