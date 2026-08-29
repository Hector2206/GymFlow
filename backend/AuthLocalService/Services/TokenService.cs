using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using AuthLocalService.Models;
using Microsoft.IdentityModel.Tokens;

namespace AuthLocalService.Services;

public class TokenService
{
    private readonly IConfiguration _configuration;

    public TokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public string GenerarToken(UsuarioLogin usuario)
    {
        var key = _configuration["Jwt:Key"];
        var issuer = _configuration["Jwt:Issuer"];
        var audience = _configuration["Jwt:Audience"];

        if (string.IsNullOrWhiteSpace(key))
        {
            throw new Exception(
                "No se encontró Jwt:Key."
            );
        }

        var claims = new[]
        {
            new Claim(
                JwtRegisteredClaimNames.Sub,
                usuario.IdUsuario
            ),

            new Claim(
                JwtRegisteredClaimNames.Email,
                usuario.Correo
            ),

            new Claim(
                "role",
                usuario.NombreRol
            ),

            new Claim(
                "name",
                usuario.NombrePerfil
            )
        };

        var securityKey =
            new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(key)
            );

        var credentials =
            new SigningCredentials(
                securityKey,
                SecurityAlgorithms.HmacSha256
            );

        var token =
            new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: claims,
                expires: DateTime.UtcNow.AddHours(8),
                signingCredentials: credentials
            );

        return new JwtSecurityTokenHandler()
            .WriteToken(token);
    }
}