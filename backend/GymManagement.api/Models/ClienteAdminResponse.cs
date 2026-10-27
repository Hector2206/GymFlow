namespace GymManagement.api.Models;

public class ClienteAdminResponse
{
    public int IdCliente { get; init; }
    public string NombreCompleto { get; init; } = string.Empty;
    public string Correo { get; init; } = string.Empty;
    public string Telefono { get; init; } = string.Empty;
    public int IdMembresia { get; init; }
    public string NombrePlan { get; init; } = string.Empty;
    public string Estatus { get; init; } = string.Empty;
    public string Vigencia { get; init; } = string.Empty;
    public DateOnly? FechaVencimiento { get; init; }
}