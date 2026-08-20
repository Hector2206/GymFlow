using System.Text.RegularExpressions;

namespace GymManagement.api.Validators;

public static class EmailValidator
{
    public static bool EsCorreoValido(string correo)
    {
        if (string.IsNullOrWhiteSpace(correo))
        {
            return false;
        }

        string patron = @"^[^@\s]+@[^@\s]+\.[^@\s]+$";

        return Regex.IsMatch(correo, patron);
    }
}