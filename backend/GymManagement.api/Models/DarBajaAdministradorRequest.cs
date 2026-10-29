
namespace GymManagement.api.Models;

public class DarBajaAdministradorRequest
{
    public string MotivoBaja { get; set; } = string.Empty;

    public DateOnly FechaBaja { get; set; }
}
