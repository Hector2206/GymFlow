
namespace GymManagement.api.Models;

public class EditarAdministradorRequest
{
    public string NombreCompleto { get; set; } = string.Empty;

    public string Correo { get; set; } = string.Empty;

    public string Telefono { get; set; } = string.Empty;

    public string Horario { get; set; } = string.Empty;
}
