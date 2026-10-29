
using System.Text.Json.Serialization;

namespace ClienteAltaService.Models;

[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public class CambiarMembresiaClienteRequest
{
    public int IdMembresia { get; set; }
}
