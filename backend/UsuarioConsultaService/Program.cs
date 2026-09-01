using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();


// ===============================
// CORS
// ===============================

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


// ===============================
// JWT
// ===============================

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


// ===============================
// APP
// ===============================

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// CORS antes de autenticación y autorización
app.UseCors("GymFlowCors");

app.UseAuthentication();
app.UseAuthorization();


// ===============================
// HEALTH
// ===============================

app.MapGet("/health", () =>
{
    return Results.Ok(new
    {
        service = "UsuarioConsultaService",
        status = "Healthy",
        timestamp = DateTime.UtcNow
    });
});


// ===============================
// USUARIO ACTUAL
// ===============================

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