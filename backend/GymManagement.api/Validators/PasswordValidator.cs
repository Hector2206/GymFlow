namespace GymManagement.api.Validators;

public static class PasswordValidator
{
    public static bool EsPasswordValida(string password)
    {
        if (string.IsNullOrWhiteSpace(password))
        {
            return false;
        }

        return password.Length >= 6;
    }
}