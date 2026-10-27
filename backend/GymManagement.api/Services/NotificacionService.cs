using Npgsql;
using NpgsqlTypes;

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
}