namespace ClienteAltaService.Models;

public class CrearClienteRequest
{
    public string Correo { get; set; } = "";
    public string Password { get; set; } = "";
    public string NombreCompleto { get; set; } = "";
    public string? Telefono { get; set; }
    public int IdMembresia { get; set; }
}