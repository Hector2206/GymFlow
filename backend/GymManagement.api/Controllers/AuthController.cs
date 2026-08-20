using Microsoft.AspNetCore.Mvc;
using GymManagement.api.Models;
using GymManagement.api.Validators;
using GymManagement.api.Services;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace GymManagement.api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly TokenService _tokenService;
    private readonly UsuarioService _usuarioService;

     public AuthController(
        TokenService tokenService,
        UsuarioService usuarioService
    )
    {
        _tokenService = tokenService;
        _usuarioService = usuarioService;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Correo) ||
            string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new
            {
                mensaje = "Correo y contraseña son obligatorios"
            });
        }

        if (!EmailValidator.EsCorreoValido(request.Correo))
        {
            return BadRequest(new
            {
                mensaje = "El correo no tiene un formato válido"
            });
        }

        if (!PasswordValidator.EsPasswordValida(request.Password))
        {
            return BadRequest(new
            {
                mensaje = "La contraseña debe tener al menos 6 caracteres"
            });
        }
        var usuario =
            await _usuarioService.BuscarPorCorreo(
                request.Correo
            );

        if (usuario == null)
        {
            return Unauthorized(new
            {
                mensaje = "Correo o contraseña incorrectos"
            });
        }

        if (!usuario.Activo)
        {
            return Unauthorized(new
            {
                mensaje = "El usuario está desactivado"
            });
        }

        var token =
        _tokenService.GenerarToken(
            usuario.Id,
            usuario.Email,
            usuario.Rol
        );

       return Ok(new
        {
            mensaje = "Inicio de sesión correcto",
            token = token,
            usuario = new
            {
                id = usuario.Id,
                email = usuario.Email,
                rol = usuario.Rol
            }
        });
        
    }
    [Authorize]
    [HttpGet("me")]
    public IActionResult Me()
    {
        var id = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("sub")?.Value;

        var email = User.FindFirst(ClaimTypes.Email)?.Value
                    ?? User.FindFirst("email")?.Value;

        var rol = User.FindFirst(ClaimTypes.Role)?.Value;

        return Ok(new
        {
            id = id,
            email = email,
            rol = rol
        });
    }
    [Authorize(Roles = "Administrador")]
    [HttpGet("admin")]
    public IActionResult AdminOnly()
    {
        return Ok(new
        {
            mensaje = "Acceso permitido para Administrador"
        });
    }
    [Authorize(Roles = "Recepcionista")]
    [HttpGet("recepcion")]
    public IActionResult RecepcionOnly()
    {
        return Ok(new
        {
            mensaje = "Acceso permitido para Recepcionista"
        });
    }
    [Authorize(Roles = "Cliente")]
    [HttpGet("cliente")]
    public IActionResult ClienteOnly()
    {
        return Ok(new
        {
            mensaje = "Acceso permitido para Cliente"
        });
    }
}