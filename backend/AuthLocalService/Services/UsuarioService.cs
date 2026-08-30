using AuthLocalService.Models;
using Npgsql;

namespace AuthLocalService.Services;

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
                contrasena_hash,
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

            ContrasenaHash =
                reader["contrasena_hash"].ToString() ?? "",

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
}