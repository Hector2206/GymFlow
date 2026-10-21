namespace GymManagement.api.Models;

public class SalarioPersonalResponse
{
    public long IdSalario { get; init; }
    public int IdPersonal { get; init; }
    public decimal Monto { get; init; }
    public string Periodicidad { get; init; } = string.Empty;
    public DateOnly VigenteDesde { get; init; }
    public DateOnly? VigenteHasta { get; init; }
    public string? Motivo { get; init; }
    public int? RegistradoPor { get; init; }
    public DateTime CreadoEn { get; init; }
}