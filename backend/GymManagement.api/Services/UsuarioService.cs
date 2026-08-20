using Npgsql;
using GymManagement.api.Models;

namespace GymManagement.api.Services;

public class UsuarioService
{
    private readonly IConfiguration _configuration;

    public UsuarioService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public async Task<UsuarioLogin?> BuscarPorCorreo(string correo)
    {
        var connectionString =
            _configuration.GetConnectionString("PostgreSQL");

        await using var connection =
            new NpgsqlConnection(connectionString);

        await connection.OpenAsync();

        const string sql = """
            SELECT
                u.id,
                u.email,
                u.password_hash,
                u.activo,
                r.nombre AS rol
            FROM usuarios u
            INNER JOIN roles r
                ON u.rol_id = r.id
            WHERE u.email = @correo
            LIMIT 1;
            """;

        await using var command =
            new NpgsqlCommand(sql, connection);

        command.Parameters.AddWithValue("@correo", correo);

        await using var reader =
            await command.ExecuteReaderAsync();

        if (!await reader.ReadAsync())
        {
            return null;
        }

        return new UsuarioLogin
        {
            Id = reader.GetGuid(
                reader.GetOrdinal("id")
            ),

            Email = reader.GetString(
                reader.GetOrdinal("email")
            ),

            PasswordHash = reader.GetString(
                reader.GetOrdinal("password_hash")
            ),

            Activo = reader.GetBoolean(
                reader.GetOrdinal("activo")
            ),

            Rol = reader.GetString(
                reader.GetOrdinal("rol")
            )
        };
    }
}