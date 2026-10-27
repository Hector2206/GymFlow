namespace GymManagement.api.Models;

public class NotificacionResponse
{
    public long IdNotificacion { get; init; }
    public string Tipo { get; init; } = string.Empty;
    public string Titulo { get; init; } = string.Empty;
    public string Mensaje { get; init; } = string.Empty;
    public DateOnly FechaVencimiento { get; init; }
    public bool Leida { get; init; }
    public DateTime? FechaLectura { get; init; }
    public DateTime CreadoEn { get; init; }
}