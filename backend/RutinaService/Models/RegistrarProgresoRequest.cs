
namespace RutinaService.Models;

public class RegistrarProgresoRequest
{
    public int IdEjercicio { get; set; }

    public decimal PesoUtilizado { get; set; }

    // Opcional: formato YYYY-MM-DD
    public string? FechaEntrenamiento { get; set; }
}
