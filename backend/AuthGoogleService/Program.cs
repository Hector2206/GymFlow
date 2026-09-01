using AuthGoogleService.Models;
using AuthGoogleService.Services;
using Google.Apis.Auth;
using Npgsql;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();

builder.Services.AddScoped<GoogleAuthService>();
builder.Services.AddScoped<UsuarioService>();
builder.Services.AddScoped<TokenService>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("GymFlowCors", policy =>
    {
        policy
            .SetIsOriginAllowed(origin =>
            {
                if (string.IsNullOrWhiteSpace(origin))
                    return false;

                if (!Uri.TryCreate(origin, UriKind.Absolute, out var uri))
                    return false;

                // DESARROLLO
                // Permite Flutter Web y Angular desde cualquier puerto localhost
                if (uri.Host == "localhost" || uri.Host == "127.0.0.1")
                    return true;

                // PRODUCCIÓN
                var allowedOrigins = new[]
                {
                    "https://gymflow-web-lkvv.onrender.com"
                };

                return allowedOrigins.Contains(origin);
            })
            .WithMethods(
                "GET",
                "POST",
                "PUT",
                "DELETE",
                "OPTIONS"
            )
            .WithHeaders(
                "Content-Type",
                "Authorization"
            );
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors("GymFlowCors");

app.MapGet("/health", () =>
{
    return Results.Ok(new
    {
        service = "AuthGoogleService",
        status = "Healthy",
        timestamp = DateTime.UtcNow
    });
});

app.MapPost(
    "/api/auth/login-google",
    async (
        GoogleLoginRequest request,
        GoogleAuthService googleAuthService,
        UsuarioService usuarioService,
        TokenService tokenService
    ) =>
    {
        if (string.IsNullOrWhiteSpace(request.Token))
        {
            return Results.BadRequest(new
            {
                mensaje = "El token de Google es obligatorio"
            });
        }

        try
        {
            var payload =
                await googleAuthService.ValidarToken(
                    request.Token
                );

            var correo = payload.Email;
            var googleId = payload.Subject;

            if (string.IsNullOrWhiteSpace(correo))
            {
                return Results.Unauthorized();
            }

            var usuario =
                await usuarioService.BuscarPorCorreo(
                    correo
                );

            if (usuario is null)
            {
                return Results.Json(
                    new
                    {
                        mensaje =
                            "No tienes una cuenta registrada. Acude a recepción."
                    },
                    statusCode: 401
                );
            }

            if (string.IsNullOrWhiteSpace(usuario.GoogleId))
            {
                await usuarioService.VincularGoogle(
                    correo,
                    googleId
                );

                usuario.GoogleId = googleId;
            }
            else if (usuario.GoogleId != googleId)
            {
                return Results.Json(
                    new
                    {
                        mensaje =
                            "La cuenta de Google no coincide con la registrada."
                    },
                    statusCode: 403
                );
            }

            var token =
                tokenService.GenerarToken(usuario);

            return Results.Ok(new
            {
                token,
                usuario = new
                {
                    idUsuario = usuario.IdUsuario,
                    correo = usuario.Correo,
                    role = usuario.NombreRol,
                    name = usuario.NombrePerfil
                }
            });
        }
        catch (InvalidJwtException)
        {
            return Results.Unauthorized();
        }
        catch (PostgresException ex)
        {
            return Results.Problem(
                title: "Error de base de datos",
                detail: ex.MessageText,
                statusCode: 500
            );
        }
        catch (Exception ex)
        {
            return Results.Problem(
                title: "Error interno",
                detail: ex.Message,
                statusCode: 500
            );
        }
    }
);

app.Run();