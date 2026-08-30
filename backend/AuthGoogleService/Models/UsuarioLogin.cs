namespace AuthGoogleService.Models;

public class UsuarioLogin
{
    public string IdUsuario { get; set; } = "";
    public string Correo { get; set; } = "";
    public string? GoogleId { get; set; }
    public int IdRol { get; set; }
    public string NombreRol { get; set; } = "";
    public string NombrePerfil { get; set; } = "";
}