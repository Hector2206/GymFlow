using System.Security.Claims;
using Npgsql;

namespace RutinaService.Services;

public class EntrenadorService
{
    private readonly IConfiguration _configuration;

    public EntrenadorService(
        IConfiguration configuration
    )
    {
        _configuration = configuration;
    }

    public async Task<int?> ObtenerIdPersonalAsync(
        ClaimsPrincipal usuario
    )
    {
        var sub =
            usuario.FindFirst("sub")?.Value;

        if (string.IsNullOrWhiteSpace(sub) ||
            !int.TryParse(sub, out var idUsuario))
        {
            return null;
        }

        var connectionString =
            _configuration.GetConnectionString(
                "PostgreSQL"
            );

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "No existe la cadena de conexión PostgreSQL."
            );
        }

        await using var connection =
            new NpgsqlConnection(connectionString);

        await connection.OpenAsync();

        await using var command =
            new NpgsqlCommand(
                """
                SELECT id_personal
                FROM personal
                WHERE id_usuario = @id_usuario
                LIMIT 1;
                """,
                connection
            );

        command.Parameters.AddWithValue(
            "id_usuario",
            idUsuario
        );

        var resultado =
            await command.ExecuteScalarAsync();

        if (resultado is null ||
            resultado == DBNull.Value)
        {
            return null;
        }

        return Convert.ToInt32(resultado);
    }
}