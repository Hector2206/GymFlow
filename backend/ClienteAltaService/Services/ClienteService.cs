using ClienteAltaService.Models;
using Npgsql;

namespace ClienteAltaService.Services;

public class ClienteService
{
    private readonly IConfiguration _configuration;
    private readonly PasswordService _passwordService;

    public ClienteService(
        IConfiguration configuration,
        PasswordService passwordService)
    {
        _configuration = configuration;
        _passwordService = passwordService;
    }

    public async Task CrearCliente(
        CrearClienteRequest request,
        string idEmpleado)
    {
        var passwordHash =
            _passwordService.GenerarHash(request.Password);

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

        await using var transaction =
            await connection.BeginTransactionAsync();

        try
        {
            // Auditoría: usuario que realiza la acción
            await using (
                var auditCommand = new NpgsqlCommand(
                    """
                    SELECT set_config(
                        'gymflow.usuario_actual',
                        @usuario_actual,
                        true
                    );
                    """,
                    connection,
                    transaction
                )
            )
            {
                auditCommand.Parameters.AddWithValue(
                    "usuario_actual",
                    idEmpleado
                );

                await auditCommand.ExecuteScalarAsync();
            }

            // Stored Procedure de alta
            await using (
                var command = new NpgsqlCommand(
                    """
                    CALL sp_alta_cliente(
                        @p_correo,
                        @p_contrasena_hash,
                        @p_id_asistencia,
                        @p_nombre_completo,
                        @p_telefono,
                        @p_id_membresia,
                        @p_costo_mensual,
                        @p_costo_anual
                    );
                    """,
                    connection,
                    transaction
                )
            )
            {
                command.Parameters.AddWithValue(
                    "p_correo",
                    request.Correo
                );

                command.Parameters.AddWithValue(
                    "p_contrasena_hash",
                    passwordHash
                );

                command.Parameters.AddWithValue(
                    "p_id_asistencia",
                    request.IdAsistencia
                );

                command.Parameters.AddWithValue(
                    "p_nombre_completo",
                    request.NombreCompleto
                );

                command.Parameters.AddWithValue(
                    "p_telefono",
                    request.Telefono ?? ""
                );

                command.Parameters.AddWithValue(
                    "p_id_membresia",
                    request.IdMembresia
                );

                command.Parameters.AddWithValue(
                    "p_costo_mensual",
                    request.CostoMensual
                );

                command.Parameters.AddWithValue(
                    "p_costo_anual",
                    request.CostoAnual
                );

                await command.ExecuteNonQueryAsync();
            }

            await transaction.CommitAsync();
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }
}