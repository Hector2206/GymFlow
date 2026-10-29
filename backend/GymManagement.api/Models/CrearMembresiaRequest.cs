namespace GymManagement.api.Models;

public class CrearMembresiaRequest
{
    public string? NombrePlan { get; set; }
    public string? Descripcion { get; set; }
    public decimal CostoMensual { get; set; }
    public decimal CostoAnualidad { get; set; }
}