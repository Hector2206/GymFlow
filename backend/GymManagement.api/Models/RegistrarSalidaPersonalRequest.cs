
using System.Text.Json.Serialization;

namespace GymManagement.api.Models;

[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public class RegistrarSalidaPersonalRequest
{
    public TimeOnly HoraSalida { get; set; }
}
