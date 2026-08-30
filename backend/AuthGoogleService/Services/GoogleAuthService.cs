using Google.Apis.Auth;

namespace AuthGoogleService.Services;

public class GoogleAuthService
{
    private readonly IConfiguration _configuration;

    public GoogleAuthService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public async Task<GoogleJsonWebSignature.Payload> ValidarToken(
        string token)
    {
        var clientId =
            _configuration["Google:ClientId"];

        if (string.IsNullOrWhiteSpace(clientId))
        {
            throw new Exception(
                "No se encontró Google:ClientId."
            );
        }

        var settings =
            new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = new[] { clientId }
            };

        return await GoogleJsonWebSignature.ValidateAsync(
            token,
            settings
        );
    }
}