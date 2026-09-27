using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Npgsql;
using RutinaService.Models;

var builder = WebApplication.CreateBuilder(args);

// ===============================
// OPENAPI
// ===============================

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

                if (uri.Host == "localhost" || uri.Host == "127.0.0.1")
                    return true;

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

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

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
        service = "RutinaService",
        status = "Healthy",
        timestamp = DateTime.UtcNow
    });
});

// ===============================
// CREAR EJERCICIO
// #905
// ===============================

app.MapPost(
    "/api/ejercicios",
    async (
        CrearEjercicioRequest request,
        IConfiguration configuration
    ) =>
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

        try
        {
            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            await using var command =
                new NpgsqlCommand(
                    """
                    INSERT INTO ejercicios (
                        nombre,
                        descripcion
                    )
                    VALUES (
                        @nombre,
                        @descripcion
                    )
                    RETURNING id_ejercicio;
                    """,
                    connection
                );

            command.Parameters.AddWithValue(
                "nombre",
                request.Nombre
            );

            command.Parameters.AddWithValue(
                "descripcion",
                (object?)request.Descripcion
                ?? DBNull.Value
            );

            var idEjercicio =
                Convert.ToInt32(
                    await command.ExecuteScalarAsync()
                );

            return Results.Created(
                $"/api/ejercicios/{idEjercicio}",
                new
                {
                    idEjercicio,
                    nombre = request.Nombre,
                    descripcion = request.Descripcion,
                    estado = true
                }
            );
        }
        catch (PostgresException ex)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "No se pudo registrar el ejercicio.",
                detalle = ex.MessageText
            });
        }
        catch (Exception)
        {
            return Results.Problem(
                title: "Error al registrar ejercicio",
                detail: "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization();

app.Run();
