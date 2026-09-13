namespace ClienteAltaService.Models;

public class RegistrarPagoRequest
{
    public int IdCliente { get; set; }
    public decimal Monto { get; set; }
    public string TipoPago { get; set; } = "";
}