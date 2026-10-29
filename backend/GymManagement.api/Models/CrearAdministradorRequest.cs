
namespace GymManagement.api.Models;

public class CrearAdministradorRequest
{
    public string NombreCompleto { get; set; } = string.Empty;

    public string Correo { get; set; } = string.Empty;

    public string Telefono { get; set; } = string.Empty;

    public DateOnly FechaContratacion { get; set; }

    public decimal Sueldo { get; set; }

    public string Horario { get; set; } = string.Empty;

    public string Password { get; set; } = string.Empty;
}
