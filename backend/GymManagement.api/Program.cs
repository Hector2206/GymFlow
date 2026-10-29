
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
builder.Services.AddScoped<DashboardService>();
builder.Services.AddScoped<ClienteAdminService>();
builder.Services.AddScoped<NotificacionService>();
builder.Services.AddHostedService<NotificacionWorker>();
builder.Services.AddScoped<MembresiaService>();
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

    app.MapGet("/api/admin/personal/{id:int}/salarios",
    async (
        int id,
        PersonalService personalService,
        ClaimsPrincipal usuario
    ) =>
    {
        if (!int.TryParse(
                usuario.FindFirst("sub")?.Value,
                out var idAdministrador) ||
            idAdministrador <= 0)
        {
            return Results.Unauthorized();
        }

        try
        {
            var historial =
                await personalService.ObtenerHistorialSalarios(
                    id,
                    idAdministrador);

            return Results.Ok(historial);
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
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new
            {
                mensaje = ex.Message
            });
        }
        catch
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al consultar historial salarial",
                detail: "No se pudo obtener el historial salarial."
            );
        }
    })
    .RequireAuthorization("SoloAdministrador");

    app.MapPost("/api/admin/personal/{id:int}/salarios",
    async (
        int id,
        GymManagement.api.Models.CambiarSalarioRequest request,
        PersonalService personalService,
        ClaimsPrincipal usuario
    ) =>
    {
        if (!int.TryParse(
                usuario.FindFirst("sub")?.Value,
                out var idAdministrador) ||
            idAdministrador <= 0)
        {
            return Results.Unauthorized();
        }

        try
        {
            var idSalario = await personalService.CambiarSalario(
                id,
                request,
                idAdministrador);

            return Results.Created(
                $"/api/admin/personal/{id}/salarios",
                new
                {
                    mensaje = "Sueldo actualizado correctamente.",
                    idPersonal = id,
                    idSalario
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
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new
            {
                mensaje = ex.Message
            });
        }
        catch (PostgresException ex)
            when (ex.SqlState == PostgresErrorCodes.UniqueViolation)
        {
            return Results.Conflict(new
            {
                mensaje = "Existe un conflicto con el salario vigente. Consulta el historial antes de reintentar."
            });
        }
        catch
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al cambiar sueldo",
                detail: "No se pudo completar el cambio de sueldo.");
        }
    })
    .RequireAuthorization("SoloAdministrador");

    app.MapGet("/api/admin/personal/{id:int}/nomina",
    async (
        int id,
        PersonalService personalService,
        ClaimsPrincipal usuario
    ) =>
    {
        if (!int.TryParse(
                usuario.FindFirst("sub")?.Value,
                out var idAdministrador) ||
            idAdministrador <= 0)
        {
            return Results.Unauthorized();
        }

        try
        {
            var pagos = await personalService.ObtenerPagosNomina(
                id,
                idAdministrador);

            return Results.Ok(pagos);
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
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new
            {
                mensaje = ex.Message
            });
        }
        catch
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al consultar pagos de nómina",
                detail: "No se pudieron obtener los pagos de nómina.");
        }
    })
    .RequireAuthorization("SoloAdministrador");

    app.MapPost("/api/admin/personal/{id:int}/nomina",
    async (
        int id,
        GymManagement.api.Models.RegistrarPagoNominaRequest request,
        PersonalService personalService,
        ClaimsPrincipal usuario
    ) =>
    {
        if (!int.TryParse(
                usuario.FindFirst("sub")?.Value,
                out var idAdministrador) ||
            idAdministrador <= 0)
        {
            return Results.Unauthorized();
        }

        try
        {
            var idPago = await personalService.RegistrarPagoNomina(
                id,
                request,
                idAdministrador);

            return Results.Created(
                $"/api/admin/personal/{id}/nomina",
                new
                {
                    mensaje = "Pago de nómina registrado correctamente.",
                    idPersonal = id,
                    idPago
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
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new
            {
                mensaje = ex.Message
            });
        }
        catch (PostgresException ex)
            when (ex.SqlState == PostgresErrorCodes.UniqueViolation)
        {
            return Results.Conflict(new
            {
                mensaje = "Ya existe un pago registrado para ese periodo."
            });
        }
        catch
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al registrar pago de nómina",
                detail: "No se pudo completar el registro del pago.");
        }
    })
    .RequireAuthorization("SoloAdministrador");

    app.MapPatch(
    "/api/admin/personal/{id:int}/nomina/{idPago:long}/cancelacion",
    async (
        int id,
        long idPago,
        GymManagement.api.Models.CancelarPagoNominaRequest request,
        PersonalService personalService,
        ClaimsPrincipal usuario
    ) =>
    {
        if (!int.TryParse(
                usuario.FindFirst("sub")?.Value,
                out var idAdministrador) ||
            idAdministrador <= 0)
        {
            return Results.Unauthorized();
        }

        try
        {
            await personalService.CancelarPagoNomina(
                id,
                idPago,
                request,
                idAdministrador);

            return Results.Ok(new
            {
                mensaje = "Pago de nómina cancelado correctamente.",
                idPersonal = id,
                idPago
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
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new
            {
                mensaje = ex.Message
            });
        }
        catch
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al cancelar pago de nómina",
                detail: "No se pudo completar la cancelación.");
        }
    })
    .RequireAuthorization("SoloAdministrador");

    app.MapGet("/api/admin/dashboard/total-clientes",
    async (
        DashboardService dashboardService,
        ClaimsPrincipal usuario
    ) =>
    {
        if (!int.TryParse(
                usuario.FindFirst("sub")?.Value,
                out var idAdministrador) ||
            idAdministrador <= 0)
        {
            return Results.Unauthorized();
        }

        try
        {
            var total = await dashboardService.ObtenerTotalClientes(
                idAdministrador);

            return Results.Ok(new
            {
                totalClientes = total
            });
        }
        catch (UnauthorizedAccessException)
        {
            return Results.Forbid();
        }
        catch
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al consultar total de clientes",
                detail: "No se pudo obtener el indicador.");
        }
    })
    .RequireAuthorization("SoloAdministrador");

    app.MapGet("/api/admin/dashboard/membresias-activas",
    async (
        DashboardService dashboardService,
        ClaimsPrincipal usuario
    ) =>
    {
        if (!int.TryParse(
                usuario.FindFirst("sub")?.Value,
                out var idAdministrador) ||
            idAdministrador <= 0)
        {
            return Results.Unauthorized();
        }

        try
        {
            var total =
                await dashboardService.ObtenerMembresiasActivas(
                    idAdministrador);

            return Results.Ok(new
            {
                membresiasActivas = total
            });
        }
        catch (UnauthorizedAccessException)
        {
            return Results.Forbid();
        }
        catch
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al consultar membresías activas",
                detail: "No se pudo obtener el indicador.");
        }
    })
    .RequireAuthorization("SoloAdministrador");

    app.MapGet("/api/admin/dashboard/asistencias-dia",
    async (
        DashboardService dashboardService,
        ClaimsPrincipal usuario
    ) =>
    {
        if (!int.TryParse(
                usuario.FindFirst("sub")?.Value,
                out var idAdministrador) ||
            idAdministrador <= 0)
        {
            return Results.Unauthorized();
        }

        try
        {
            var total =
                await dashboardService.ObtenerAsistenciasDia(
                    idAdministrador);

            return Results.Ok(new
            {
                asistenciasDia = total
            });
        }
        catch (UnauthorizedAccessException)
        {
            return Results.Forbid();
        }
        catch
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al consultar asistencias del día",
                detail: "No se pudo obtener el indicador.");
        }
    })
    .RequireAuthorization("SoloAdministrador");

    app.MapGet("/api/admin/dashboard/pagos-registrados",
    async (
        DashboardService dashboardService,
        ClaimsPrincipal usuario
    ) =>
    {
        if (!int.TryParse(
                usuario.FindFirst("sub")?.Value,
                out var idAdministrador) ||
            idAdministrador <= 0)
        {
            return Results.Unauthorized();
        }

        try
        {
            var total =
                await dashboardService.ObtenerPagosRegistrados(
                    idAdministrador);

            return Results.Ok(new
            {
                pagosRegistrados = total
            });
        }
        catch (UnauthorizedAccessException)
        {
            return Results.Forbid();
        }
        catch
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al consultar pagos registrados",
                detail: "No se pudo obtener el indicador.");
        }
    })
    .RequireAuthorization("SoloAdministrador");

    app.MapGet("/api/admin/dashboard/ingresos-periodo",
    async (
        DateOnly? desde,
        DateOnly? hasta,
        DashboardService dashboardService,
        ClaimsPrincipal usuario
    ) =>
    {
        if (!int.TryParse(
                usuario.FindFirst("sub")?.Value,
                out var idAdministrador) ||
            idAdministrador <= 0)
        {
            return Results.Unauthorized();
        }

        if (!desde.HasValue || !hasta.HasValue)
        {
            return Results.BadRequest(new
            {
                mensaje = "Los parámetros desde y hasta son obligatorios."
            });
        }

        try
        {
            var total = await dashboardService.ObtenerIngresosPeriodo(
                idAdministrador,
                desde.Value,
                hasta.Value);

            return Results.Ok(new
            {
                desde = desde.Value.ToString(
                    "yyyy-MM-dd",
                    System.Globalization.CultureInfo.InvariantCulture),
                hasta = hasta.Value.ToString(
                    "yyyy-MM-dd",
                    System.Globalization.CultureInfo.InvariantCulture),
                ingresosPeriodo = total
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
                title: "Error al consultar ingresos del periodo",
                detail: "No se pudo obtener el indicador.");
        }
    })
    .RequireAuthorization("SoloAdministrador");

    app.MapGet("/api/admin/clientes",
    async (
        string? nombre,
        string? correo,
        string? estatus,
        string? vigencia,
        int? idMembresia,
        ClienteAdminService clienteService,
        ClaimsPrincipal usuario
    ) =>
    {
        if (!int.TryParse(
                usuario.FindFirst("sub")?.Value,
                out var idAdministrador) ||
            idAdministrador <= 0)
        {
            return Results.Unauthorized();
        }

        var filtros = new GymManagement.api.Models.BuscarClientesRequest
        {
            Nombre = nombre,
            Correo = correo,
            Estatus = estatus,
            Vigencia = vigencia,
            IdMembresia = idMembresia
        };

        try
        {
            var clientes = await clienteService.BuscarClientes(
                filtros,
                idAdministrador);

            return Results.Ok(clientes);
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
                title: "Error al buscar clientes",
                detail: "No se pudo completar la consulta.");
        }
    })
    .RequireAuthorization("SoloAdministrador");

    app.MapGet("/api/notificaciones",
    async (
        NotificacionService notificacionService,
        ClaimsPrincipal usuario,
        CancellationToken cancellationToken
    ) =>
    {
        if (!int.TryParse(
                usuario.FindFirst("sub")?.Value,
                out var idUsuario) ||
            idUsuario <= 0)
        {
            return Results.Unauthorized();
        }

        try
        {
            var notificaciones =
                await notificacionService.ObtenerNotificaciones(
                    idUsuario,
                    cancellationToken);

            return Results.Ok(notificaciones);
        }
        catch (UnauthorizedAccessException)
        {
            return Results.Forbid();
        }
        catch (OperationCanceledException)
            when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al consultar notificaciones",
                detail: "No se pudieron obtener las notificaciones.");
        }
    })
    .RequireAuthorization();

    app.MapGet("/api/notificaciones/no-leidas",
    async (
        NotificacionService notificacionService,
        ClaimsPrincipal usuario,
        CancellationToken cancellationToken
    ) =>
    {
        if (!int.TryParse(
                usuario.FindFirst("sub")?.Value,
                out var idUsuario) ||
            idUsuario <= 0)
        {
            return Results.Unauthorized();
        }

        try
        {
            var total = await notificacionService.ObtenerNoLeidas(
                idUsuario,
                cancellationToken);

            return Results.Ok(new
            {
                noLeidas = total
            });
        }
        catch (UnauthorizedAccessException)
        {
            return Results.Forbid();
        }
        catch (OperationCanceledException)
            when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al contar notificaciones",
                detail: "No se pudo obtener el contador de no leídas.");
        }
    })
    .RequireAuthorization();

    app.MapPatch("/api/notificaciones/{id:long}/lectura",
    async (
        long id,
        NotificacionService notificacionService,
        ClaimsPrincipal usuario,
        CancellationToken cancellationToken
    ) =>
    {
        if (!int.TryParse(
                usuario.FindFirst("sub")?.Value,
                out var idUsuario) ||
            idUsuario <= 0)
        {
            return Results.Unauthorized();
        }

        try
        {
            await notificacionService.MarcarComoLeida(
                id,
                idUsuario,
                cancellationToken);

            return Results.Ok(new
            {
                mensaje = "Notificación marcada como leída.",
                idNotificacion = id
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
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new
            {
                mensaje = ex.Message
            });
        }
        catch (OperationCanceledException)
            when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al marcar notificación",
                detail: "No se pudo actualizar la notificación.");
        }
    })
    .RequireAuthorization();

    app.MapGet("/api/admin/membresias",
    async (
        MembresiaService membresiaService,
        ClaimsPrincipal usuario
    ) =>
    {
        if (!int.TryParse(
            usuario.FindFirst("sub")?.Value,
            out var idAdministrador))
        {
            return Results.Unauthorized();
        }

        try
        {
            var membresias =
                await membresiaService.ObtenerMembresias(idAdministrador);

            return Results.Ok(membresias);
        }
        catch (UnauthorizedAccessException)
        {
            return Results.Forbid();
        }
        catch
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al consultar membresías");
        }
    })
    .RequireAuthorization("SoloAdministrador");

    app.MapGet("/api/membresias/activas",
    async (MembresiaService membresiaService) =>
    {
        try
        {
            var membresias =
                await membresiaService.ObtenerMembresiasActivas();

            return Results.Ok(membresias);
        }
        catch (Exception)
        {
            return Results.Problem(
                statusCode: 500,
                title: "Error al consultar membresías activas");
        }
    })
    .RequireAuthorization(policy =>
        policy.RequireRole("Recepción", "Administrador"));


    app.MapPost("/api/admin/membresias",
    async (
        GymManagement.api.Models.CrearMembresiaRequest request,
        MembresiaService membresiaService,
        ClaimsPrincipal usuario
    ) =>
    {
        if (!int.TryParse(
            usuario.FindFirst("sub")?.Value,
            out var idAdministrador))
        {
            return Results.Unauthorized();
        }

        try
        {
            var idMembresia =
                await membresiaService.CrearMembresia(
                    request, idAdministrador);

            return Results.Created(
                $"/api/admin/membresias/{idMembresia}",
                new
                {
                    mensaje = "Membresía creada correctamente.",
                    idMembresia
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
        catch (PostgresException ex)
            when (ex.SqlState ==
                  PostgresErrorCodes.UniqueViolation)
        {
            return Results.Conflict(new
            {
                mensaje = "Ya existe una membresía con ese nombre."
            });
        }
        catch (Exception ex)
        {
            app.Logger.LogError(
                ex, "Error al crear membresía");

            return Results.Problem(
                statusCode: 500,
                title: "Error al crear membresía");
            }
    })
    .RequireAuthorization("SoloAdministrador");

app.Run();
