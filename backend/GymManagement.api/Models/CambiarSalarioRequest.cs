namespace GymManagement.api.Models;

[System.Text.Json.Serialization.JsonUnmappedMemberHandling(
    System.Text.Json.Serialization.JsonUnmappedMemberHandling.Disallow)]
public class CambiarSalarioRequest
{
    public decimal? Monto { get; set; }
    public DateOnly VigenteDesde { get; set; }
    public string Motivo { get; set; } = string.Empty;

    public void NormalizarYValidar(DateOnly fechaOperacion)
    {
        Motivo = Motivo?.Trim() ?? string.Empty;

        if (Monto is null)
            throw new ArgumentException("El monto es obligatorio.");

        // Límite de personal.salario: NUMERIC(10,2).
        if (Monto.Value < 0 || Monto.Value > 99999999.99m)
            throw new ArgumentException(
                "El monto debe estar entre 0 y 99999999.99.");

        if (decimal.Round(Monto.Value, 2) != Monto.Value)
            throw new ArgumentException(
                "El monto debe tener como máximo dos decimales.");

        if (VigenteDesde != fechaOperacion)
            throw new ArgumentException(
                "La vigencia debe comenzar el día de la operación.");

        if (string.IsNullOrWhiteSpace(Motivo))
            throw new ArgumentException("El motivo es obligatorio.");
    }
}