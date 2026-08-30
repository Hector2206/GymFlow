namespace ClienteAltaService.Services;

public class PasswordService
{
    public string GenerarHash(string password)
    {
        return BCrypt.Net.BCrypt.HashPassword(password);
    }
}