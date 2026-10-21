
using Npgsql;
using System.Text;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using GymManagement.api.Services;

var builder = WebApplication.CreateBuilder(args);

// ========================================
// OPENAPI
// ========================================

builder.Services.AddOpenApi();
builder.Services.AddScoped<PersonalService>();

// ========================================
// CORS
// ========================================

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy
            .AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

// ========================================
// AUTENTICACION JWT
// ========================================

var jwtKey = builder.Configuration["Jwt:Key"];
var jwtIssuer = builder.Configuration["Jwt:Issuer"];
var jwtAudience = builder.Configuration["Jwt:Audience"];

if (string.IsNullOrWhiteSpace(jwtKey) ||
    string.IsNullOrWhiteSpace(jwtIssuer) ||
    string.IsNullOrWhiteSpace(jwtAudience))
{
    throw new InvalidOperationException(
        "Falta configuración JWT: Key, Issuer o Audience."
    );
}

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
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

                IssuerSigningKey = new SymmetricSecurityKey(
                    Encoding.UTF8.GetBytes(jwtKey)
                ),

                RoleClaimType = "role",
                NameClaimType = "name",

                ClockSkew = TimeSpan.Zero
            };
    });

// ========================================
// AUTORIZACION
// ========================================

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("SoloAdministrador", policy =>
        policy.RequireAuthenticatedUser()
              .RequireRole("Administrador"));
});

// ========================================
// CREAR APLICACION
// ========================================

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// ========================================
// MIDDLEWARE
// ========================================

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

// ========================================
// HEALTH
// ========================================

app.MapGet("/health", () =>
{
    return Results.Ok(new
    {
        status = "Healthy",
        message = "Backend conectado correctamente",
        timestamp = DateTime.UtcNow
    });
})
.WithName("HealthCheck");

// ========================================
// CONEXION POSTGRESQL
// ========================================

app.MapGet("/ping", async (IConfiguration configuration) =>
{
    try
    {
        var connectionString =
            configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            return Results.Problem(
                statusCode: 503,
                title: "Database unavailable"
            );
        }

        await using var connection =
            new NpgsqlConnection(connectionString);

        await connection.OpenAsync();

        await using var command =
            new NpgsqlCommand("SELECT 1", connection);

        await command.ExecuteScalarAsync();

        return Results.Ok(new
        {
            status = "ok",
            database = "connected",
            message = "Conexion con PostgreSQL correcta"
        });
    }
        catch
        {
            return Results.Problem(
                statusCode: 503,
                title: "Database unavailable",
                detail: "No se pudo conectar con PostgreSQL"
            );
        }

});

// ========================================
// VERSION BASE DE DATOS
// ========================================

app.MapGet("/version", async (IConfiguration configuration) =>
{
    try
    {
        var connectionString =
            configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            return Results.Problem(
                statusCode: 503,
                title: "Database unavailable"
            );
        }

        await using var connection =
            new NpgsqlConnection(connectionString);

        await connection.OpenAsync();

        await using var command =
            new NpgsqlCommand(
                "SELECT version FROM system_versions ORDER BY id DESC LIMIT 1",
                connection
            );

        var version = await command.ExecuteScalarAsync();

        if (version == null)
        {
            return Results.NotFound(new
            {
                message = "No hay una version registrada"
            });
        }

        return Results.Ok(new
        {
            version = version.ToString()
        });
    }
    catch
    {
        return Results.Problem(
            statusCode: 503,
            title: "Database unavailable",
            detail: "No se pudo consultar la version"
        );
    }
});

// ========================================
// SPRINT 7 - VERIFICAR ADMINISTRADOR
// ========================================

app.MapGet("/api/admin/verificar-acceso",
    (ClaimsPrincipal usuario) =>
    {
        var idUsuario = usuario.FindFirst("sub")?.Value;

        return Results.Ok(new
        {
            mensaje = "Acceso de Administrador autorizado",
            idUsuario = idUsuario,
            rol = "Administrador"
        });
    })
    .RequireAuthorization("SoloAdministrador");

// ========================================
// INICIAR APLICACION
// ========================================


app.MapPost("/api/admin/personal",
    async (
        GymManagement.api.Models.CrearPersonalRequest request,
        GymManagement.api.Services.PersonalService personalService,
        System.Security.Claims.ClaimsPrincipal usuario
    ) =>
    {
        var idClaim = usuario.FindFirst("sub")?.Value;

        if (!int.TryParse(idClaim, out var idAdministrador))
        {
            return Results.Unauthorized();
        }

        try
        {
            var idPersonal = await personalService.CrearPersonal(
                request,
                idAdministrador
            );

            return Results.Created(
                $"/api/admin/personal/{idPersonal}",
                new
                {
                    mensaje = "Empleado registrado correctamente",
                    idPersonal
                }
            );
        }
        catch (UnauthorizedAccessException)
        {
            return Results.Forbid();
        }
        catch (ArgumentException ex)
        {
            return Results.BadRequest(new
            {
                mensaje = ex.Message
            });
        }
        catch (Npgsql.PostgresException ex)
            when (ex.SqlState == "23505")
        {
            return Results.Conflict(new
            {
                mensaje = "Ya existe un registro con esos datos."
            });
        }
        catch (Exception)
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al registrar empleado",
                detail: "Ocurrió un error interno."
            );
        }
    })
    .RequireAuthorization("SoloAdministrador");


app.MapGet("/api/admin/personal",
    async (
        GymManagement.api.Services.PersonalService personalService
    ) =>
    {
        try
        {
            var empleados =
                await personalService.ObtenerPersonal();

            return Results.Ok(empleados);
        }
        catch (Exception)
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al consultar empleados",
                detail: "No se pudo obtener el personal."
            );
        }
    })
    .RequireAuthorization("SoloAdministrador");


app.MapGet("/api/admin/personal/{id:int}",
    async (
        int id,
        GymManagement.api.Services.PersonalService personalService
    ) =>
    {
        if (id <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje = "El ID del empleado no es válido."
            });
        }

        try
        {
            var empleados =
                await personalService.ObtenerPersonal();

            var empleado = empleados
                .FirstOrDefault(e =>
                {
                    var propiedad = e.GetType()
                        .GetProperty("idPersonal");

                    return propiedad != null &&
                        (int)propiedad.GetValue(e)! == id;
                });

            if (empleado == null)
            {
                return Results.NotFound(new
                {
                    mensaje = "Empleado no encontrado."
                });
            }

            return Results.Ok(empleado);
        }
        catch
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al consultar empleado"
            );
        }
    })
    .RequireAuthorization("SoloAdministrador");


app.MapPatch("/api/admin/personal/{id:int}/baja",
    async (
        int id,
        GymManagement.api.Models.DarBajaPersonalRequest request,
        GymManagement.api.Services.PersonalService personalService,
        HttpContext context
    ) =>
    {
        if (!int.TryParse(
            context.User.FindFirst("sub")?.Value,
            out var idAdministrador))
        {
            return Results.Unauthorized();
        }

        try
        {
            var clientesDesasignados =
                await personalService.DarDeBajaPersonal(
                    id,
                    request.Motivo,
                    idAdministrador);

            return Results.Ok(new
            {
                mensaje = "Empleado dado de baja correctamente.",
                idPersonal = id,
                clientesDesasignados
            });
        }
        catch (UnauthorizedAccessException)
        {
            return Results.Forbid();
        }
        catch (ArgumentException ex)
        {
            return Results.BadRequest(new
            {
                mensaje = ex.Message
            });
        }
        catch
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al dar de baja al empleado."
            );
        }
    })
    .RequireAuthorization("SoloAdministrador");

app.MapPut("/api/admin/personal/{id:int}",
    async (int id, GymManagement.api.Models.EditarPersonalRequest request,
        PersonalService personalService, ClaimsPrincipal usuario) =>
    {
        if (!int.TryParse(usuario.FindFirst("sub")?.Value, out var admin) || admin <= 0)
            return Results.Unauthorized();

        try
        {
            await personalService.EditarPersonal(id, request, admin);
            return Results.Ok(new { mensaje = "Empleado actualizado correctamente.", idPersonal = id });
        }
        catch (UnauthorizedAccessException) { return Results.Forbid(); }
        catch (ArgumentException ex) { return Results.BadRequest(new { mensaje = ex.Message }); }
        catch (KeyNotFoundException ex) { return Results.NotFound(new { mensaje = ex.Message }); }
        catch (PostgresException ex) when (ex.SqlState == PostgresErrorCodes.UniqueViolation)
        {
            return Results.Conflict(new { mensaje = "Ya existe un registro con esos datos." });
        }
        catch (InvalidOperationException ex) when (ex.Message == "No se puede editar un empleado dado de baja.")
        {
            return Results.Conflict(new { mensaje = ex.Message });
        }
        catch
        {
            return Results.Problem(statusCode: 500, title: "Error al editar empleado",
                detail: "Ocurrió un error interno.");
        }
    })
    .RequireAuthorization("SoloAdministrador");

app.Run();
