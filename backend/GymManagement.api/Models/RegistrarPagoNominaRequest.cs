using System.Text.Json.Serialization;

namespace GymManagement.api.Models;

[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]
public class RegistrarPagoNominaRequest
{
    public DateOnly PeriodoInicio { get; set; }
    public DateOnly PeriodoFin { get; set; }
    public decimal? Monto { get; set; }
    public DateOnly FechaPago { get; set; }
    public string Metodo { get; set; } = string.Empty;
    public string? Referencia { get; set; }
    public string? Observaciones { get; set; }

    public void NormalizarYValidar(DateOnly fechaOperacion)
    {
        Metodo = Metodo?.Trim() ?? string.Empty;
        Referencia = string.IsNullOrWhiteSpace(Referencia)
            ? null
            : Referencia.Trim();
        Observaciones = string.IsNullOrWhiteSpace(Observaciones)
            ? null
            : Observaciones.Trim();

        if (PeriodoInicio == default || PeriodoFin == default)
            throw new ArgumentException(
                "El inicio y el fin del periodo son obligatorios.");

        if (PeriodoFin < PeriodoInicio)
            throw new ArgumentException(
                "El fin del periodo no puede ser anterior al inicio.");

        if (Monto is null)
            throw new ArgumentException("El monto es obligatorio.");

        // Límite de personal_nomina_pagos.monto: NUMERIC(12,2).
        if (Monto.Value <= 0 || Monto.Value > 9999999999.99m)
            throw new ArgumentException(
                "El monto debe ser mayor que cero y no superar 9999999999.99.");

        if (decimal.Round(Monto.Value, 2) != Monto.Value)
            throw new ArgumentException(
                "El monto debe tener como máximo dos decimales.");

        if (FechaPago == default || FechaPago > fechaOperacion)
            throw new ArgumentException(
                "La fecha de pago es obligatoria y no puede ser futura.");

        if (Metodo != "Efectivo" && Metodo != "Transferencia")
            throw new ArgumentException(
                "El método debe ser Efectivo o Transferencia.");

        if (Referencia is { Length: > 100 })
            throw new ArgumentException(
                "La referencia no puede superar 100 caracteres.");

        if (Metodo == "Transferencia" && Referencia is null)
            throw new ArgumentException(
                "La referencia es obligatoria para transferencias.");
    }
}