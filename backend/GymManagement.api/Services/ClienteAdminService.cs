using GymManagement.api.Models;
using Npgsql;
using NpgsqlTypes;

namespace GymManagement.api.Services;

public class ClienteAdminService
{
    private readonly IConfiguration _configuration;

    public ClienteAdminService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public async Task<List<ClienteAdminResponse>> BuscarClientes(
        BuscarClientesRequest request,
        int idAdministrador)
    {
        if (idAdministrador <= 0)
            throw new UnauthorizedAccessException(
                "Administrador no autorizado.");

        request.NormalizarYValidar();

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

        await using var command =
            new NpgsqlCommand();

        command.Connection = connection;
        command.Transaction = transaction;

        var condiciones = new List<string>();

        if (request.Nombre is not null)
        {
            condiciones.Add(
                "nombre_completo ILIKE @nombre ESCAPE '!'");

            command.Parameters.AddWithValue(
                "nombre",
                NpgsqlDbType.Text,
                CrearPatronLiteral(request.Nombre));
        }

        if (request.Correo is not null)
        {
            condiciones.Add(
                "correo ILIKE @correo ESCAPE '!'");

            command.Parameters.AddWithValue(
                "correo",
                NpgsqlDbType.Text,
                CrearPatronLiteral(request.Correo));
        }

        if (request.Estatus is not null)
        {
            condiciones.Add("estatus = @estatus");

            command.Parameters.AddWithValue(
                "estatus",
                NpgsqlDbType.Text,
                request.Estatus);
        }

        if (request.Vigencia is not null)
        {
            condiciones.Add("vigencia = @vigencia");

            command.Parameters.AddWithValue(
                "vigencia",
                NpgsqlDbType.Text,
                request.Vigencia);
        }

        if (request.IdMembresia.HasValue)
        {
            condiciones.Add("id_membresia = @idMembresia");

            command.Parameters.AddWithValue(
                "idMembresia",
                NpgsqlDbType.Integer,
                request.IdMembresia.Value);
        }

        var sql = """
            SELECT id_cliente,
                   nombre_completo,
                   correo,
                   telefono,
                   id_membresia,
                   nombre_plan,
                   estatus,
                   vigencia,
                   fecha_vencimiento
            FROM public.vw_admin_clientes
            """;

        if (condiciones.Count > 0)
            sql += "\nWHERE " + string.Join(" AND ", condiciones);

        sql += "\nORDER BY nombre_completo, id_cliente;";

        command.CommandText = sql;

        var clientes = new List<ClienteAdminResponse>();

        await using (var reader = await command.ExecuteReaderAsync())
        {
            while (await reader.ReadAsync())
            {
                clientes.Add(new ClienteAdminResponse
                {
                    IdCliente = reader.GetInt32(0),
                    NombreCompleto = reader.GetString(1),
                    Correo = reader.GetString(2),
                    Telefono = reader.GetString(3),
                    IdMembresia = reader.GetInt32(4),
                    NombrePlan = reader.GetString(5),
                    Estatus = reader.GetString(6),
                    Vigencia = reader.GetString(7),
                    FechaVencimiento = reader.IsDBNull(8)
                        ? null
                        : reader.GetFieldValue<DateOnly>(8)
                });
            }
        }

        await transaction.CommitAsync();

        return clientes;
    }

    private static string CrearPatronLiteral(string texto)
    {
        var literal = texto
            .Replace("!", "!!")
            .Replace("%", "!%")
            .Replace("_", "!_");

        return "%" + literal + "%";
    }
}