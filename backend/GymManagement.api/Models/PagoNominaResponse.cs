namespace GymManagement.api.Models;

public class PagoNominaResponse
{
    public long IdPago { get; init; }
    public int IdPersonal { get; init; }
    public long IdSalario { get; init; }

    public DateOnly PeriodoInicio { get; init; }
    public DateOnly PeriodoFin { get; init; }
    public decimal Monto { get; init; }
    public DateOnly FechaPago { get; init; }

    public string Metodo { get; init; } = string.Empty;
    public string? Referencia { get; init; }
    public string? Observaciones { get; init; }
    public string Estado { get; init; } = string.Empty;

    public int RegistradoPor { get; init; }
    public int? CanceladoPor { get; init; }
    public DateTime? FechaCancelacion { get; init; }
    public string? MotivoCancelacion { get; init; }
    public DateTime CreadoEn { get; init; }
}