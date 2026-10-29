
using System.Text.Json.Serialization;

namespace GymManagement.api.Models;

[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public class RegistrarAsistenciaPersonalRequest
{
    public int IdPersonal { get; set; }

    public DateOnly Fecha { get; set; }

    public TimeOnly HoraEntrada { get; set; }

    public void Validar()
    {
        if (IdPersonal <= 0)
        {
            throw new ArgumentException(
                "Debe seleccionar un empleado válido.");
        }

        if (Fecha == default)
        {
            throw new ArgumentException(
                "La fecha de asistencia es obligatoria.");
        }

        if (Fecha > DateOnly.FromDateTime(DateTime.Today))
        {
            throw new ArgumentException(
                "No se pueden registrar asistencias futuras.");
        }
    }
}
