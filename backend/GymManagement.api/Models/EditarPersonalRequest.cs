using System.Net.Mail;
using System.Text.Json.Serialization;

namespace GymManagement.api.Models;

[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public class EditarPersonalRequest
{
    public string NombreCompleto { get; set; } = string.Empty;
    public string Correo { get; set; } = string.Empty;
    public string Telefono { get; set; } = string.Empty;
    public string Horario { get; set; } = string.Empty;

    public void NormalizarYValidar()
    {
        NombreCompleto = NombreCompleto?.Trim() ?? string.Empty;
        Correo = Correo?.Trim().ToLowerInvariant() ?? string.Empty;
        Telefono = Telefono?.Trim() ?? string.Empty;
        Horario = Horario?.Trim() ?? string.Empty;

        if (NombreCompleto.Length is < 1 or > 150 ||
            Correo.Length is < 1 or > 150 ||
            Telefono.Length is < 1 or > 20 ||
            Horario.Length is < 1 or > 100)
            throw new ArgumentException(
                "Nombre, correo, teléfono y horario son obligatorios; máximos: 150, 150, 20 y 100 caracteres.");

        if (!MailAddress.TryCreate(Correo, out var direccion) ||
            direccion.Address != Correo)
            throw new ArgumentException("El correo no es válido.");
    }
}
