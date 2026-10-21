using System.Text.Json.Serialization;

namespace GymManagement.api.Models;

[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public class CancelarPagoNominaRequest
{
    public string Motivo { get; set; } = string.Empty;

    public void NormalizarYValidar()
    {
        Motivo = Motivo?.Trim() ?? string.Empty;

        if (string.IsNullOrWhiteSpace(Motivo))
            throw new ArgumentException(
                "El motivo de cancelación es obligatorio.");
    }
}