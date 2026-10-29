using System.Text.Json.Serialization;

namespace ClienteAltaService.Models;

[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public class RegistrarPagoRequest
{
    public int IdCliente { get; set; }
    public string TipoPago { get; set; } = "";
}