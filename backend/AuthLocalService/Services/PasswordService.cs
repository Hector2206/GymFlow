namespace AuthLocalService.Services;

public class PasswordService
{
    public bool VerificarPassword(
        string password,
        string passwordHash)
    {
        return BCrypt.Net.BCrypt.Verify(
            password,
            passwordHash
        );
    }
}