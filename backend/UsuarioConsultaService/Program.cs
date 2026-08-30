using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

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

var jwtKey = builder.Configuration["Jwt:Key"];
var jwtIssuer = builder.Configuration["Jwt:Issuer"];
var jwtAudience = builder.Configuration["Jwt:Audience"];

if (string.IsNullOrWhiteSpace(jwtKey))
{
    throw new InvalidOperationException(
        "No se encontró la configuración Jwt:Key."
    );
}

builder.Services
    .AddAuthentication(
        JwtBearerDefaults.AuthenticationScheme
    )
    .AddJwtBearer(options =>
    {
         options.MapInboundClaims = false;
        options.TokenValidationParameters =
            new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,

                ValidIssuer = jwtIssuer,
                ValidAudience = jwtAudience,

                IssuerSigningKey =
                    new SymmetricSecurityKey(
                        Encoding.UTF8.GetBytes(jwtKey)
                    ),

                RoleClaimType = "role",
                NameClaimType = "name",

                ClockSkew = TimeSpan.Zero
            };
    });

builder.Services.AddAuthorization();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors("GymFlowWeb");
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/health", () =>
{
    return Results.Ok(new
    {
        service = "UsuarioConsultaService",
        status = "Healthy",
        timestamp = DateTime.UtcNow
    });
});

app.MapGet(
    "/api/usuarios/me",
    (ClaimsPrincipal usuario) =>
    {
        var idUsuario =
            usuario.FindFirst("sub")?.Value
            ?? usuario.FindFirst(
                ClaimTypes.NameIdentifier
            )?.Value;

        var correo =
            usuario.FindFirst("email")?.Value
            ?? usuario.FindFirst(
                ClaimTypes.Email
            )?.Value;

        var role =
            usuario.FindFirst("role")?.Value
            ?? usuario.FindFirst(
                ClaimTypes.Role
            )?.Value;

        var nombre =
            usuario.FindFirst("name")?.Value
            ?? usuario.Identity?.Name;

        if (string.IsNullOrWhiteSpace(idUsuario))
        {
            return Results.Unauthorized();
        }

        return Results.Ok(new
        {
            idUsuario,
            correo,
            role,
            name = nombre
        });
    }
)
.RequireAuthorization();

app.Run();
