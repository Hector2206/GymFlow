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
                title: "Error al registrar cliente",
                detail: "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Recepcionista");
});

// ===============================
// MI CODIGO DE ACCESO
// ===============================

app.MapGet(
    "/api/clientes/mi-codigo-acceso",
    async (
        ClaimsPrincipal usuario,
        IConfiguration configuration
    ) =>
    {
        var idUsuario =
            usuario.FindFirst("sub")?.Value
            ?? usuario.FindFirst(
                ClaimTypes.NameIdentifier
            )?.Value;

        if (string.IsNullOrWhiteSpace(idUsuario))
        {
            return Results.Unauthorized();
        }

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
            """
            SELECT
                id_cliente,
                id_asistencia,
                nombre_completo
            FROM clientes
            WHERE id_usuario = @id_usuario;
            """,
            connection
        );

        command.Parameters.AddWithValue(
            "id_usuario",
            int.Parse(idUsuario)
        );

        await using var reader =
            await command.ExecuteReaderAsync();

        if (!await reader.ReadAsync())
        {
           return Results.NotFound(new
            {
                accesoAprobado = false,
                motivo = "CodigoNoEncontrado",
                mensaje = "Código de acceso no encontrado."
            });
        }

        return Results.Ok(new
        {
            idCliente = reader.GetInt32(0),
            codigoAcceso = reader.GetString(1),
            nombreCompleto = reader.GetString(2)
        });
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Cliente");
});
    // ===============================
    // REGISTRAR ASISTENCIA POR CODIGO
    // ===============================

    app.MapPost(
        "/api/asistencias/codigo",
        async (
            RegistroAsistenciaPorCodigo request,
            IConfiguration configuration
        ) =>
        {
            if (string.IsNullOrWhiteSpace(request.CodigoAcceso))
            {
                return Results.BadRequest(new
                {
                    mensaje = "El código de acceso es obligatorio."
                });
            }

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

           var codigoAcceso =
                request.CodigoAcceso.Trim();

            await using var command =
                new NpgsqlCommand(
                    """
                    SELECT
                        c.id_cliente,
                        c.nombre_completo,
                        u.estatus,
                        c.id_membresia,
                        m.nombre_plan,
                        c.fecha_pago_mensual,
                        c.fecha_pago_anualidad
                    FROM clientes c
                    INNER JOIN usuarios u
                        ON c.id_usuario = u.id_usuario
                    INNER JOIN membresias m
                        ON c.id_membresia = m.id_membresia
                    WHERE c.id_asistencia = @codigo_acceso;
                    """,
                    connection
                );

            command.Parameters.AddWithValue(
                "codigo_acceso",
                codigoAcceso
            );

            await using var reader =
                await command.ExecuteReaderAsync();

            if (!await reader.ReadAsync())
            {
                return Results.NotFound(new
                {
                    mensaje = "Código de acceso no encontrado."
                });
            }

            var idCliente =
                reader.GetInt32(0);

            var nombreCompleto =
                reader.GetString(1);

            var estatus =
                reader.GetString(2);
                if (!estatus.Equals(
                    "Activo",
                    StringComparison.OrdinalIgnoreCase
                ))
            {
                return Results.BadRequest(new
                {
                    accesoAprobado = false,
                    motivo = "ClienteInactivo",
                    mensaje = "El cliente está inactivo."
                });
            }
            var idMembresia =
                reader.GetInt32(3);

            var nombrePlan =
                reader.GetString(4);

            DateTime? fechaPagoMensual =
                reader.IsDBNull(5)
                    ? null
                    : reader.GetDateTime(5);

            DateTime? fechaPagoAnualidad =
                reader.IsDBNull(6)
                    ? null
                    : reader.GetDateTime(6);

            DateTime? vencimientoMensual =
                fechaPagoMensual?.AddMonths(1);

            DateTime? vencimientoAnual =
                fechaPagoAnualidad?.AddYears(1);

            DateTime? fechaVencimiento = null;

            if (vencimientoMensual.HasValue)
            {
                fechaVencimiento = vencimientoMensual;
            }

            if (
                vencimientoAnual.HasValue &&
                (
                    !fechaVencimiento.HasValue ||
                    vencimientoAnual.Value > fechaVencimiento.Value
                )
            )
            {
                fechaVencimiento = vencimientoAnual;
            }

            if (!fechaVencimiento.HasValue)
            {
                return Results.BadRequest(new
                {
                    accesoAprobado = false,
                    motivo = "SinMembresiaVigente",
                    mensaje =
                        "El cliente no tiene una membresía vigente."
                });
            }

            if (fechaVencimiento.Value.Date < DateTime.Today)
            {
                return Results.BadRequest(new
                {
                    accesoAprobado = false,
                    motivo = "MembresiaVencida",
                    mensaje =
                        "La membresía del cliente está vencida.",
                    fechaVencimiento =
                        fechaVencimiento.Value.Date
                });
            }
            await reader.CloseAsync();

            await using var asistenciaCommand =
            new NpgsqlCommand(
                """
                INSERT INTO asistencias (
                    id_cliente,
                    estado_acceso,
                    origen_registro
                )
                VALUES (
                    @id_cliente,
                    @estado_acceso,
                    @origen_registro
                )
                RETURNING fecha_hora;
                """,
                connection
            );

            asistenciaCommand.Parameters.AddWithValue(
                "id_cliente",
                idCliente
            );
            asistenciaCommand.Parameters.AddWithValue(
                "estado_acceso",
                "Aprobado"
            );

            asistenciaCommand.Parameters.AddWithValue(
                "origen_registro",
                "LectorCodigo"
            );

            var fechaHoraAsistencia =
                (DateTime)(
                    await asistenciaCommand.ExecuteScalarAsync()
                    ?? throw new Exception(
                        "No se pudo obtener la fecha de asistencia."
                    )
                );

          return Results.Ok(new
            {
                accesoAprobado = true,
                idCliente,
                nombreCompleto,
                codigoAcceso,
                idMembresia,
                nombrePlan,
                fechaVencimiento,
                fechaHoraAsistencia,
                mensaje = "Acceso aprobado."
            });
        }
    )
    .RequireAuthorization(policy =>
    {
        policy.RequireRole("Recepcionista");
    });

// ===============================
// ASISTENCIAS POR CLIENTE
// ===============================

app.MapGet(
    "/api/asistencias/cliente/{idCliente:int}",
    async (
        int idCliente,
        IConfiguration configuration
    ) =>
    {
        if (idCliente <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje = "El id del cliente no es válido."
            });
        }

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
                """
                SELECT
                    id_asistencia_registro,
                    fecha_hora,
                    estado_acceso,
                    origen_registro
                FROM asistencias
                WHERE id_cliente = @id_cliente
                ORDER BY fecha_hora DESC;
                """,
                connection
            );

        command.Parameters.AddWithValue(
            "id_cliente",
            idCliente
        );

        await using var reader =
            await command.ExecuteReaderAsync();

        var asistencias =
            new List<object>();

        while (await reader.ReadAsync())
        {
            asistencias.Add(new
            {
                idAsistencia =
                    reader.GetInt32(0),
                fechaHora =
                    reader.GetDateTime(1),
                estadoAcceso =
                    reader.GetString(2),
                origenRegistro =
                    reader.GetString(3)
            });
        }

        return Results.Ok(new
        {
            idCliente,
            asistencias
        });
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Recepcionista");
});

// ===============================
// MIS ASISTENCIAS
// ===============================

app.MapGet(
    "/api/asistencias/mis-asistencias",
    async (
        ClaimsPrincipal usuario,
        IConfiguration configuration
    ) =>
    {
        var idUsuario =
            usuario.FindFirst("sub")?.Value
            ?? usuario.FindFirst(
                ClaimTypes.NameIdentifier
            )?.Value;

        if (string.IsNullOrWhiteSpace(idUsuario))
        {
            return Results.Unauthorized();
        }

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
                """
                SELECT
                    a.id_asistencia_registro,
                    a.fecha_hora,
                    a.estado_acceso,
                    a.origen_registro
                FROM asistencias a
                INNER JOIN clientes c
                    ON a.id_cliente = c.id_cliente
                WHERE c.id_usuario = @id_usuario
                ORDER BY a.fecha_hora DESC;
                """,
                connection
            );

        command.Parameters.AddWithValue(
            "id_usuario",
            int.Parse(idUsuario)
        );

        await using var reader =
            await command.ExecuteReaderAsync();

        var asistencias =
            new List<object>();

        while (await reader.ReadAsync())
        {
            asistencias.Add(new
            {
                idAsistencia =
                    reader.GetInt32(0),
                fechaHora =
                    reader.GetDateTime(1),
                estadoAcceso =
                    reader.GetString(2),
                origenRegistro =
                    reader.GetString(3)
            });
        }

        return Results.Ok(new
        {
            asistencias
        });
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Cliente");
});

// ===============================
// REGISTRAR PAGO
// ===============================

app.MapPost(
    "/api/pagos",
    async (
        RegistrarPagoRequest request,
        ClaimsPrincipal usuario,
        IConfiguration configuration
    ) =>
    {
        if (request.IdCliente <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje = "El cliente no es válido."
            });
        }

        if (request.Monto <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje = "El monto debe ser mayor a cero."
            });
        }

        if (
            !request.TipoPago.Equals(
                "Mensualidad",
                StringComparison.OrdinalIgnoreCase
            )
            &&
            !request.TipoPago.Equals(
                "Anualidad",
                StringComparison.OrdinalIgnoreCase
            )
        )
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "El tipo de pago debe ser Mensualidad o Anualidad."
            });
        }

        var idUsuario =
            usuario.FindFirst("sub")?.Value
            ?? usuario.FindFirst(
                ClaimTypes.NameIdentifier
            )?.Value;

        if (string.IsNullOrWhiteSpace(idUsuario))
        {
            return Results.Unauthorized();
        }

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

        // VALIDAR QUE EL CLIENTE EXISTA
        await using var validarClienteCommand =
            new NpgsqlCommand(
                """
                SELECT COUNT(*)
                FROM clientes
                WHERE id_cliente = @id_cliente;
                """,
                connection
            );

        validarClienteCommand.Parameters.AddWithValue(
            "id_cliente",
            request.IdCliente
        );

        var clienteExiste =
            Convert.ToInt32(
                await validarClienteCommand.ExecuteScalarAsync()
            ) > 0;

        if (!clienteExiste)
        {
            return Results.NotFound(new
            {
                mensaje = "El cliente no existe."
            });
        }

        // OBTENER RECEPCIONISTA DESDE EL USUARIO AUTENTICADO
        await using var recepcionistaCommand =
            new NpgsqlCommand(
                """
                SELECT id_personal
                FROM personal
                WHERE id_usuario = @id_usuario;
                """,
                connection
            );

        recepcionistaCommand.Parameters.AddWithValue(
            "id_usuario",
            int.Parse(idUsuario)
        );

        var idRecepcionistaObj =
            await recepcionistaCommand.ExecuteScalarAsync();

        if (idRecepcionistaObj is null)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "No se encontró el perfil de recepcionista."
            });
        }

        var idRecepcionista =
            Convert.ToInt32(idRecepcionistaObj);

        var tipoPagoNormalizado =
            request.TipoPago.Equals(
                "Mensualidad",
                StringComparison.OrdinalIgnoreCase
            )
                ? "Mensualidad"
                : "Anualidad";

        // REGISTRAR PAGO
        await using var pagoCommand =
            new NpgsqlCommand(
                """
                CALL sp_registrar_pago(
                    @p_id_cliente,
                    @p_id_recepcionista,
                    @p_monto,
                    @p_tipo
                );
                """,
                connection
            );

        pagoCommand.Parameters.AddWithValue(
            "p_id_cliente",
            request.IdCliente
        );

        pagoCommand.Parameters.AddWithValue(
            "p_id_recepcionista",
            idRecepcionista
        );

        pagoCommand.Parameters.AddWithValue(
            "p_monto",
            request.Monto
        );

        pagoCommand.Parameters.AddWithValue(
            "p_tipo",
            tipoPagoNormalizado
        );

        await pagoCommand.ExecuteNonQueryAsync();

        return Results.Ok(new
        {
            pagoRegistrado = true,
            idCliente = request.IdCliente,
            monto = request.Monto,
            tipoPago = tipoPagoNormalizado,
            mensaje = "Pago registrado correctamente."
        });
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Recepcionista");
});

// ===============================
// PAGOS POR CLIENTE
// ===============================

app.MapGet(
    "/api/pagos/cliente/{idCliente:int}",
    async (
        int idCliente,
        IConfiguration configuration
    ) =>
    {
        if (idCliente <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje = "El id del cliente no es válido."
            });
        }

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
                """
                SELECT
                    id_pago,
                    monto_pagado,
                    tipo_pago,
                    fecha_transaccion
                FROM historial_pagos
                WHERE id_cliente = @id_cliente
                ORDER BY fecha_transaccion DESC;
                """,
                connection
            );

        command.Parameters.AddWithValue(
            "id_cliente",
            idCliente
        );

        await using var reader =
            await command.ExecuteReaderAsync();

        var pagos =
            new List<object>();

        while (await reader.ReadAsync())
        {
            pagos.Add(new
            {
                idPago =
                    reader.GetInt32(0),
                monto =
                    reader.GetDecimal(1),
                tipoPago =
                    reader.GetString(2),
                fechaTransaccion =
                    reader.GetDateTime(3)
            });
        }

        return Results.Ok(new
        {
            idCliente,
            pagos
        });
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Recepcionista");
});

app.Run();