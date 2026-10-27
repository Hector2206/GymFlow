namespace GymManagement.api.Models;

public class BuscarClientesRequest
{
    public string? Nombre { get; set; }
    public string? Correo { get; set; }
    public string? Estatus { get; set; }
    public string? Vigencia { get; set; }
    public int? IdMembresia { get; set; }

    public void NormalizarYValidar()
    {
        Nombre = Limpiar(Nombre);
        Correo = Limpiar(Correo);
        Estatus = Limpiar(Estatus);
        Vigencia = Limpiar(Vigencia);

        if (Nombre is { Length: > 150 })
            throw new ArgumentException(
                "El nombre no puede superar 150 caracteres.");

        if (Correo is { Length: > 150 })
            throw new ArgumentException(
                "El correo no puede superar 150 caracteres.");

        if (Estatus is not null &&
            Estatus != "Activo" &&
            Estatus != "Inactivo")
        {
            throw new ArgumentException(
                "El estatus debe ser Activo o Inactivo.");
        }

        if (Vigencia is not null &&
            Vigencia != "Vigente" &&
            Vigencia != "Vencida" &&
            Vigencia != "SinPagos")
        {
            throw new ArgumentException(
                "La vigencia debe ser Vigente, Vencida o SinPagos.");
        }

        if (IdMembresia.HasValue && IdMembresia.Value <= 0)
            throw new ArgumentException(
                "El ID de membresía debe ser un entero positivo.");
    }

    private static string? Limpiar(string? valor)
    {
        return string.IsNullOrWhiteSpace(valor)
            ? null
            : valor.Trim();
    }
}