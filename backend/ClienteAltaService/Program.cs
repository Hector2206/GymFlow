using System.Security.Claims;
using System.Text;
using ClienteAltaService.Models;
using ClienteAltaService.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Npgsql;

var builder = WebApplication.CreateBuilder(args);

// ===============================
// OPENAPI
// ===============================

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


// ===============================
// SERVICIOS
// ===============================

builder.Services.AddScoped<PasswordService>();
builder.Services.AddScoped<ClienteService>();


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

                // Nuestros JWT tendrán estos claims
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

app.UseCors("GymFlowWeb");
app.UseAuthentication();
app.UseAuthorization();


// ===============================
// HEALTH
// ===============================

app.MapGet("/health", () =>
{
    return Results.Ok(new
    {
        service = "ClienteAltaService",
        status = "Healthy",
        timestamp = DateTime.UtcNow
    });
});


// ===============================
// HEALTH BASE DE DATOS
// ===============================

app.MapGet(
    "/db-health",
    async (IConfiguration configuration) =>
    {
        try
        {
            var connectionString =
                configuration.GetConnectionString(
                    "PostgreSQL"
                );

            if (string.IsNullOrWhiteSpace(connectionString))
            {
                return Results.Problem(
                    title: "Configuración faltante",
                    detail:
                    "No existe la cadena de conexión PostgreSQL.",
                    statusCode: 500
                );
            }

            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            await using var command =
                new NpgsqlCommand(
                    "SELECT 1",
                    connection
                );

            await command.ExecuteScalarAsync();

            return Results.Ok(new
            {
                service = "ClienteAltaService",
                database = "Connected"
            });
        }
        catch (Exception ex)
        {
            return Results.Problem(
                title: "Error de conexión",
                detail: ex.Message,
                statusCode: 503
            );
        }
    }
);


// ===============================
// ALTA DE CLIENTE
// ===============================

app.MapPost(
    "/api/clientes",
    async (
        CrearClienteRequest request,
        ClienteService clienteService,
        ClaimsPrincipal usuario
    ) =>
    {
        // ===========================
        // OBTENER EMPLEADO DEL JWT
        // ===========================

        var idEmpleado =
            usuario.FindFirst("sub")?.Value
            ?? usuario.FindFirst(
                ClaimTypes.NameIdentifier
            )?.Value;

        if (string.IsNullOrWhiteSpace(idEmpleado))
        {
            return Results.Unauthorized();
        }


        // ===========================
        // VALIDACIONES
        // ===========================

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
                mensaje =
                    "La contraseña es obligatoria"
            });
        }

        if (request.Password.Length < 6)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "La contraseña debe tener al menos 6 caracteres"
            });
        }

        if (
            string.IsNullOrWhiteSpace(
                request.NombreCompleto
            )
        )
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "El nombre completo es obligatorio"
            });
        }

        if (
            string.IsNullOrWhiteSpace(
                request.IdAsistencia
            )
        )
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "El ID de asistencia es obligatorio"
            });
        }

        if (request.IdMembresia <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "La membresía no es válida"
            });
        }

        if (request.CostoMensual < 0)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "El costo mensual no puede ser negativo"
            });
        }

        if (request.CostoAnual < 0)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "El costo anual no puede ser negativo"
            });
        }


        // ===========================
        // REGISTRAR CLIENTE
        // ===========================

        try
        {
            await clienteService.CrearCliente(
                request,
                idEmpleado
            );

            return Results.Created(
                "/api/clientes",
                new
                {
                    mensaje =
                        "Cliente registrado correctamente"
                }
            );
        }
        catch (PostgresException ex)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "No se pudo registrar el cliente",
                detalle = ex.MessageText
            });
        }
        catch (Exception)
        {
            return Results.Problem(
                title : "Error al registrar cliente",
                detail : "Ocurrió un error interno.",
                statusCode : 500
            );
        }
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Recepcionista");
});


app.Run();
