
namespace GymManagement.api.Models;

public class CrearPersonalRequest
{
    public string NombreCompleto { get; set; } = string.Empty;

    public string Correo { get; set; } = string.Empty;

    public string Telefono { get; set; } = string.Empty;

    public DateOnly FechaContratacion { get; set; }

    public string Puesto { get; set; } = string.Empty;

    public decimal Sueldo { get; set; }

    public string Password { get; set; } = string.Empty;
}
