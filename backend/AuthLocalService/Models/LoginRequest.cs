namespace AuthLocalService.Models;

public class LoginRequest
{
    public string Correo { get; set; } = "";
    public string Password { get; set; } = "";
}