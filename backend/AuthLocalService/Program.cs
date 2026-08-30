using AuthLocalService.Models;
using AuthLocalService.Services;
using Npgsql;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();

var allowedOrigins =
    builder.Configuration
        .GetSection("Cors:AllowedOrigins")
        .Get<string[]>()
    ?? [];

builder.Services.AddCors(options =>
{
    options.AddPolicy("GymFlowWeb", policy =>
    {
        policy
            .WithOrigins(allowedOrigins)
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

builder.Services.AddScoped<UsuarioService>();
builder.Services.AddScoped<PasswordService>();
builder.Services.AddScoped<TokenService>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors("GymFlowWeb");

app.MapGet("/health", () =>
{
    return Results.Ok(new
    {
        service = "AuthLocalService",
        status = "Healthy",
        timestamp = DateTime.UtcNow
    });
});

app.MapPost(
    "/api/auth/login",
    async (
        LoginRequest request,
        UsuarioService usuarioService,
        PasswordService passwordService,
        TokenService tokenService
    ) =>
    {
        if (string.IsNullOrWhiteSpace(request.Correo))
        {
            return Results.BadRequest(new
            {
                mensaje = "El correo es obligatorio"
            });
        }

        if (string.IsNullOrWhiteSpace(request.Password))
        {
            return Results.BadRequest(new
            {
                mensaje = "La contraseña es obligatoria"
            });
        }

        try
        {
            var usuario =
                await usuarioService.BuscarPorCorreo(
                    request.Correo
                );

            if (usuario is null)
            {
                return Results.Unauthorized();
            }

            var passwordValido =
                passwordService.VerificarPassword(
                    request.Password,
                    usuario.ContrasenaHash
                );

            if (!passwordValido)
            {
                return Results.Unauthorized();
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
