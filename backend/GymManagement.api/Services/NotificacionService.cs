using Npgsql;
using NpgsqlTypes;
using GymManagement.api.Models;

namespace GymManagement.api.Services;

public class NotificacionService
{
    private readonly IConfiguration _configuration;

    public NotificacionService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public async Task<long> GenerarAvisosVencimiento(
        int diasAnticipacion,
        CancellationToken cancellationToken = default)
    {
        if (diasAnticipacion < 0 || diasAnticipacion > 365)
            throw new ArgumentException(
                "Los días de anticipación deben estar entre 0 y 365.");

        var connectionString =
            _configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException(
                "Falta la conexión PostgreSQL.");

        await using var connection =
            new NpgsqlConnection(connectionString);

        await connection.OpenAsync(cancellationToken);

        await using var command = new NpgsqlCommand("""
            SELECT public.fn_generar_avisos_vencimiento(@dias);
            """, connection);

        command.Parameters.AddWithValue(
            "dias",
            NpgsqlDbType.Integer,
            diasAnticipacion);

        var resultado =
            await command.ExecuteScalarAsync(cancellationToken);

        if (resultado is not long creadas)
            throw new InvalidOperationException(
                "No se pudo obtener el resultado de generación de avisos.");

        return creadas;
    }

    public async Task<List<NotificacionResponse>> ObtenerNotificaciones(
    int idUsuario,
    CancellationToken cancellationToken = default)
    {
        if (idUsuario <= 0)
            throw new UnauthorizedAccessException(
                "Usuario no autorizado.");

        var connectionString =
            _configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException(
                "Falta la conexión PostgreSQL.");

        await using var connection =
            new NpgsqlConnection(connectionString);

        await connection.OpenAsync(cancellationToken);

        await using var transaction =
            await connection.BeginTransactionAsync(cancellationToken);

        await using (var usuario = new NpgsqlCommand("""
            SELECT id_usuario
            FROM public.usuarios
            WHERE id_usuario = @id
            AND estatus = 'Activo'
            FOR SHARE;
            """, connection, transaction))
        {
            usuario.Parameters.AddWithValue("id", idUsuario);

            if (await usuario.ExecuteScalarAsync(cancellationToken) is null)
                throw new UnauthorizedAccessException(
                    "Usuario inactivo o inexistente.");
        }

        var notificaciones = new List<NotificacionResponse>();

        await using (var command = new NpgsqlCommand("""
            SELECT id_notificacion,
                tipo,
                titulo,
                mensaje,
                fecha_vencimiento,
                leida,
                fecha_lectura,
                creado_en
            FROM public.notificaciones
            WHERE id_usuario = @id
            ORDER BY creado_en DESC, id_notificacion DESC;
            """, connection, transaction))
        {
            command.Parameters.AddWithValue("id", idUsuario);

            await using var reader =
                await command.ExecuteReaderAsync(cancellationToken);

            while (await reader.ReadAsync(cancellationToken))
            {
                notificaciones.Add(new NotificacionResponse
                {
                    IdNotificacion = reader.GetInt64(0),
                    Tipo = reader.GetString(1),
                    Titulo = reader.GetString(2),
                    Mensaje = reader.GetString(3),
                    FechaVencimiento = reader.GetFieldValue<DateOnly>(4),
                    Leida = reader.GetBoolean(5),
                    FechaLectura = reader.IsDBNull(6)
                        ? null
                        : reader.GetDateTime(6),
                    CreadoEn = reader.GetDateTime(7)
                });
            }
        }

        await transaction.CommitAsync(cancellationToken);

        return notificaciones;
    }

    public async Task<long> ObtenerNoLeidas(
    int idUsuario,
    CancellationToken cancellationToken = default)
    {
        if (idUsuario <= 0)
            throw new UnauthorizedAccessException(
                "Usuario no autorizado.");

        var connectionString =
            _configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException(
                "Falta la conexión PostgreSQL.");

        await using var connection =
            new NpgsqlConnection(connectionString);

        await connection.OpenAsync(cancellationToken);

        await using var transaction =
            await connection.BeginTransactionAsync(cancellationToken);

        await using (var usuario = new NpgsqlCommand("""
            SELECT id_usuario
            FROM public.usuarios
            WHERE id_usuario = @id
            AND estatus = 'Activo'
            FOR SHARE;
            """, connection, transaction))
        {
            usuario.Parameters.AddWithValue("id", idUsuario);

            if (await usuario.ExecuteScalarAsync(cancellationToken) is null)
                throw new UnauthorizedAccessException(
                    "Usuario inactivo o inexistente.");
        }

        await using var command = new NpgsqlCommand("""
            SELECT COUNT(*)
            FROM public.notificaciones
            WHERE id_usuario = @id
            AND leida = FALSE;
            """, connection, transaction);

        command.Parameters.AddWithValue("id", idUsuario);

        var resultado =
            await command.ExecuteScalarAsync(cancellationToken);

        if (resultado is not long total)
            throw new InvalidOperationException(
                "No se pudo obtener el contador de notificaciones.");

        await transaction.CommitAsync(cancellationToken);

        return total;
    }

    public async Task MarcarComoLeida(
    long idNotificacion,
    int idUsuario,
    CancellationToken cancellationToken = default)
    {
        if (idNotificacion <= 0)
            throw new ArgumentException(
                "ID de notificación inválido.");

        if (idUsuario <= 0)
            throw new UnauthorizedAccessException(
                "Usuario no autorizado.");

        var connectionString =
            _configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException(
                "Falta la conexión PostgreSQL.");

        await using var connection =
            new NpgsqlConnection(connectionString);

        await connection.OpenAsync(cancellationToken);

        await using var transaction =
            await connection.BeginTransactionAsync(cancellationToken);

        await using (var usuario = new NpgsqlCommand("""
            SELECT id_usuario
            FROM public.usuarios
            WHERE id_usuario = @id
            AND estatus = 'Activo'
            FOR SHARE;
            """, connection, transaction))
        {
            usuario.Parameters.AddWithValue("id", idUsuario);

            if (await usuario.ExecuteScalarAsync(cancellationToken) is null)
                throw new UnauthorizedAccessException(
                    "Usuario inactivo o inexistente.");
        }

        // Bloquear únicamente una notificación del usuario autenticado.
        bool leida;

        await using (var buscar = new NpgsqlCommand("""
            SELECT leida
            FROM public.notificaciones
            WHERE id_notificacion = @notificacion
            AND id_usuario = @usuario
            FOR UPDATE;
            """, connection, transaction))
        {
            buscar.Parameters.AddWithValue(
                "notificacion", idNotificacion);
            buscar.Parameters.AddWithValue("usuario", idUsuario);

            var resultado =
                await buscar.ExecuteScalarAsync(cancellationToken);

            if (resultado is null)
                throw new KeyNotFoundException(
                    "Notificación no encontrada.");

            leida = (bool)resultado;
        }

        // Repetir la petición no modifica la primera fecha de lectura.
        if (!leida)
        {
            await using var actualizar = new NpgsqlCommand("""
                UPDATE public.notificaciones
                SET leida = TRUE,
                    fecha_lectura = CURRENT_TIMESTAMP
                WHERE id_notificacion = @notificacion
                AND id_usuario = @usuario;
                """, connection, transaction);

            actualizar.Parameters.AddWithValue(
                "notificacion", idNotificacion);
            actualizar.Parameters.AddWithValue("usuario", idUsuario);

            await actualizar.ExecuteNonQueryAsync(cancellationToken);
        }

        await transaction.CommitAsync(cancellationToken);
    }
}