namespace GymManagement.api.Models;

public class LoginResponse
{
    public string Mensaje { get; set; } = string.Empty;
    public string? Token { get; set; }
}