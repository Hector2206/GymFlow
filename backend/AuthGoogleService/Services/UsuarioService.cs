using AuthGoogleService.Models;
using Npgsql;

namespace AuthGoogleService.Services;

public class UsuarioService
{
    private readonly IConfiguration _configuration;

    public UsuarioService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public async Task<UsuarioLogin?> BuscarPorCorreo(
        string correo)
    {
        var connectionString =
            _configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new Exception(
                "No se encontró la cadena de conexión PostgreSQL."
            );
        }

        await using var connection =
            new NpgsqlConnection(connectionString);

        await connection.OpenAsync();

        const string sql = """
            SELECT
                id_usuario,
                correo,
                google_id,
                id_rol,
                nombre_rol,
                nombre_perfil
            FROM vw_usuarios_login
            WHERE correo = @correo;
            """;

        await using var command =
            new NpgsqlCommand(sql, connection);

        command.Parameters.AddWithValue(
            "correo",
            correo
        );

        await using var reader =
            await command.ExecuteReaderAsync();

        if (!await reader.ReadAsync())
        {
            return null;
        }

        return new UsuarioLogin
        {
            IdUsuario =
                reader["id_usuario"].ToString() ?? "",

            Correo =
                reader["correo"].ToString() ?? "",

            GoogleId =
                reader["google_id"] == DBNull.Value
                    ? null
                    : reader["google_id"].ToString(),

            IdRol =
                Convert.ToInt32(reader["id_rol"]),

            NombreRol =
                reader["nombre_rol"].ToString() ?? "",

            NombrePerfil =
                reader["nombre_perfil"].ToString() ?? ""
        };
    }

    public async Task VincularGoogle(
        string correo,
        string googleId)
    {
        var connectionString =
            _configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new Exception(
                "No se encontró la cadena de conexión PostgreSQL."
            );
        }

        await using var connection =
            new NpgsqlConnection(connectionString);

        await connection.OpenAsync();

        const string sql = """
            CALL sp_vincular_google(
                @p_correo,
                @p_google_id
            );
            """;

        await using var command =
            new NpgsqlCommand(sql, connection);

        command.Parameters.AddWithValue(
            "p_correo",
            correo
        );

        command.Parameters.AddWithValue(
            "p_google_id",
            googleId
        );

        await command.ExecuteNonQueryAsync();
    }
}