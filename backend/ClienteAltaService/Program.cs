using System.Security.Claims;
using System.Text;
using ClienteAltaService.Models;
using ClienteAltaService.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Npgsql;
using System.Text.Json.Serialization;

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
                    "https://gymflow-web-lkvv.onrender.com",
                    "https://www.gymflow.lat",
                    "https://gymflow.lat"
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
            "Authorization",
            "Idempotency-Key"
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
        IConfiguration configuration,
        HttpContext context
    ) =>

   {
                if (!context.Request.Headers.TryGetValue(
                "Idempotency-Key", out var claves)
            || claves.Count != 1
            || !Guid.TryParse(claves[0], out var claveIdempotencia)
            || claveIdempotencia == Guid.Empty)
        {
            return Results.BadRequest(new
            {
                mensaje = "Se requiere una Idempotency-Key UUID válida."
            });
        }
        if (request.IdCliente <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje = "El cliente no es válido."
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

        await using var transaction =
            await connection.BeginTransactionAsync();

        try
        {
            // VALIDAR QUE EL CLIENTE EXISTA
            await using var validarClienteCommand =
                new NpgsqlCommand(
                    """
                    SELECT COUNT(*)
                    FROM clientes
                    WHERE id_cliente = @id_cliente;
                    """,
                    connection,
                    transaction
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
                await transaction.RollbackAsync();

                return Results.NotFound(new
                {
                    mensaje = "El cliente no existe."
                });
            }

            // DETECTAR SI ES RENOVACION
            await using var membresiaCommand =
                new NpgsqlCommand(
                    """
                    SELECT
                        fecha_pago_mensual,
                        fecha_pago_anualidad
                    FROM clientes
                    WHERE id_cliente = @id_cliente;
                    """,
                    connection,
                    transaction
                );

            membresiaCommand.Parameters.AddWithValue(
                "id_cliente",
                request.IdCliente
            );

            await using var membresiaReader =
                await membresiaCommand.ExecuteReaderAsync();

            DateTime? fechaPagoAnterior = null;

            if (await membresiaReader.ReadAsync())
            {
                if (
                    request.TipoPago.Equals(
                        "Mensualidad",
                        StringComparison.OrdinalIgnoreCase
                    )
                    &&
                    !membresiaReader.IsDBNull(0)
                )
                {
                    fechaPagoAnterior =
                        membresiaReader.GetDateTime(0);
                }

                if (
                    request.TipoPago.Equals(
                        "Anualidad",
                        StringComparison.OrdinalIgnoreCase
                    )
                    &&
                    !membresiaReader.IsDBNull(1)
                )
                {
                    fechaPagoAnterior =
                        membresiaReader.GetDateTime(1);
                }
            }

            await membresiaReader.CloseAsync();

            var esRenovacion =
                fechaPagoAnterior.HasValue;

            // OBTENER RECEPCIONISTA
            await using var recepcionistaCommand =
                new NpgsqlCommand(
                    """
                    SELECT id_personal
                    FROM personal
                    WHERE id_usuario = @id_usuario;
                    """,
                    connection,
                    transaction
                );

            recepcionistaCommand.Parameters.AddWithValue(
                "id_usuario",
                int.Parse(idUsuario)
            );

            var idRecepcionistaObj =
                await recepcionistaCommand.ExecuteScalarAsync();

            if (idRecepcionistaObj is null)
            {
                await transaction.RollbackAsync();

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

        // REGISTRAR PAGO CON IDEMPOTENCIA

        int idPago;
        bool pagoRepetido;

        await using (var pagoCommand = new NpgsqlCommand("""
            CALL public.sp_registrar_pago_idempotente(
                @p_clave,
                @p_id_cliente,
                @p_id_recepcionista,
                @p_tipo,
                NULL::integer,
                NULL::boolean
            );
            """, connection, transaction))
        {
            pagoCommand.Parameters.AddWithValue(
                "p_clave", claveIdempotencia);

            pagoCommand.Parameters.AddWithValue(
                "p_id_cliente", request.IdCliente);

            pagoCommand.Parameters.AddWithValue(
                "p_id_recepcionista", idRecepcionista);

            pagoCommand.Parameters.AddWithValue(
                "p_tipo", tipoPagoNormalizado);

            await using var reader =
                await pagoCommand.ExecuteReaderAsync();

            if (!await reader.ReadAsync())
            {
                throw new InvalidOperationException(
                    "El procedimiento no devolvió el resultado del pago.");
            }

            idPago = reader.GetInt32(0);
            pagoRepetido = reader.GetBoolean(1);
        }

        // CONSULTAR EL MONTO REAL DEL PAGO
        decimal montoOficial;

        await using (var montoCommand = new NpgsqlCommand("""
            SELECT monto_pagado
            FROM public.historial_pagos
            WHERE id_pago = @id_pago
            AND id_cliente = @id_cliente;
            """, connection, transaction))
        {
            montoCommand.Parameters.AddWithValue(
                "id_pago", idPago);

            montoCommand.Parameters.AddWithValue(
                "id_cliente", request.IdCliente);

            var resultado = await montoCommand.ExecuteScalarAsync();

            if (resultado is null)
            {
                throw new InvalidOperationException(
                    "No se encontró el pago registrado.");
            }

            montoOficial = Convert.ToDecimal(resultado);
        }
            

            // OBTENER NUEVA VIGENCIA
            await using var vigenciaCommand =
                new NpgsqlCommand(
                    """
                    SELECT
                        fecha_pago_mensual,
                        fecha_pago_anualidad
                    FROM clientes
                    WHERE id_cliente = @id_cliente;
                    """,
                    connection,
                    transaction
                );

            vigenciaCommand.Parameters.AddWithValue(
                "id_cliente",
                request.IdCliente
            );

            await using var vigenciaReader =
                await vigenciaCommand.ExecuteReaderAsync();

            DateTime? fechaPagoActualizada = null;

            if (await vigenciaReader.ReadAsync())
            {
                if (
                    tipoPagoNormalizado == "Mensualidad"
                    &&
                    !vigenciaReader.IsDBNull(0)
                )
                {
                    fechaPagoActualizada =
                        vigenciaReader.GetDateTime(0);
                }

                if (
                    tipoPagoNormalizado == "Anualidad"
                    &&
                    !vigenciaReader.IsDBNull(1)
                )
                {
                    fechaPagoActualizada =
                        vigenciaReader.GetDateTime(1);
                }
            }

            await vigenciaReader.CloseAsync();

            if (!fechaPagoActualizada.HasValue)
            {
                throw new Exception(
                    "No se pudo obtener la nueva vigencia."
                );
            }

            var fechaVencimiento =
                tipoPagoNormalizado == "Mensualidad"
                    ? fechaPagoActualizada.Value.AddMonths(1)
                    : fechaPagoActualizada.Value.AddYears(1);

            // TODO SALIO BIEN
            await transaction.CommitAsync();

            return Results.Ok(new
            {
                pagoRegistrado = true,
                pagoRepetido,
                idPago,
                esRenovacion = pagoRepetido
                    ? (bool?)null
                    : esRenovacion,
                idCliente = request.IdCliente,
                monto = montoOficial,
                tipoPago = tipoPagoNormalizado,
                fechaVencimiento,
                mensaje = pagoRepetido
                    ? "Este pago ya había sido procesado. No se generó otro cobro."
                    : esRenovacion
                        ? "Renovación registrada correctamente."
                        : "Pago registrado correctamente."
            });
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();

            return Results.Problem(
                title: "Error al registrar pago",
                detail: ex.Message,
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
// MIS PAGOS
// ===============================

app.MapGet(
    "/api/pagos/mis-pagos",
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
                    p.id_pago,
                    p.monto_pagado,
                    p.tipo_pago,
                    p.fecha_transaccion
                FROM historial_pagos p
                INNER JOIN clientes c
                    ON p.id_cliente = c.id_cliente
                WHERE c.id_usuario = @id_usuario
                ORDER BY p.fecha_transaccion DESC;
                """,
                connection
            );

        command.Parameters.AddWithValue(
            "id_usuario",
            int.Parse(idUsuario)
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
            pagos
        });
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Cliente");
});

 // ===============================
 // LISTAR CLIENTES PARA RECEPCION
 // ===============================

app.MapGet(
    "/api/clientes",
    async (
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

        await using var connection =
            new NpgsqlConnection(connectionString);

        await connection.OpenAsync();

        await using var command =
            new NpgsqlCommand(
                """
                SELECT
                    c.id_cliente,
                    c.nombre_completo,
                    c.id_entrenador,
                    p.nombre_completo AS nombre_entrenador
                FROM clientes c
                INNER JOIN usuarios u
                    ON c.id_usuario = u.id_usuario
                LEFT JOIN personal p
                    ON c.id_entrenador = p.id_personal
                WHERE u.estatus = 'Activo'
                ORDER BY c.nombre_completo;
                """,
                connection
            );

        await using var reader =
            await command.ExecuteReaderAsync();

        var clientes =
            new List<object>();

        while (await reader.ReadAsync())
        {
            clientes.Add(new
            {
                idCliente =
                    reader.GetInt32(0),

                nombreCompleto =
                    reader.GetString(1),

                idEntrenador =
                    reader.IsDBNull(2)
                        ? (int?)null
                        : reader.GetInt32(2),

                nombreEntrenador =
                    reader.IsDBNull(3)
                        ? null
                        : reader.GetString(3)
            });
        }

        return Results.Ok(clientes);
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Recepcionista");
});

// ===============================
// HISTORIAL DE PAGOS POR CLIENTE
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

        // Primero comprobar que el cliente sí exista
        await using var clienteCommand =
            new NpgsqlCommand(
                """
                SELECT COUNT(*)
                FROM clientes
                WHERE id_cliente = @id_cliente;
                """,
                connection
            );

        clienteCommand.Parameters.AddWithValue(
            "id_cliente",
            idCliente
        );

        var clienteExiste =
            Convert.ToInt32(
                await clienteCommand.ExecuteScalarAsync()
            ) > 0;

        if (!clienteExiste)
        {
            return Results.NotFound(new
            {
                mensaje = "El cliente no existe."
            });
        }

        // Obtener historial de pagos
        await using var pagosCommand =
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

        pagosCommand.Parameters.AddWithValue(
            "id_cliente",
            idCliente
        );

        await using var reader =
            await pagosCommand.ExecuteReaderAsync();

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


 // ============================================
 // LISTAR ENTRENADORES - RECEPCION
 // ============================================

app.MapGet(
    "/api/entrenadores",
    async (IConfiguration configuration) =>
    {
        var connectionString =
            configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            return Results.Problem(
                title: "Configuración faltante",
                detail: "No existe la conexión PostgreSQL.",
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
                    SELECT
                        p.id_personal,
                        p.nombre_completo
                    FROM personal p
                    INNER JOIN usuarios u
                        ON u.id_usuario = p.id_usuario
                    INNER JOIN roles r
                        ON r.id_rol = u.id_rol
                    WHERE r.nombre = 'Entrenador'
                      AND u.estatus = 'Activo'
                    ORDER BY p.nombre_completo;
                    """,
                    connection
                );

            await using var reader =
                await command.ExecuteReaderAsync();

            var entrenadores = new List<object>();

            while (await reader.ReadAsync())
            {
                entrenadores.Add(new
                {
                    idEntrenador = reader.GetInt32(0),
                    nombreCompleto = reader.GetString(1)
                });
            }

            return Results.Ok(entrenadores);
        }
        catch (Exception ex)
        {
            app.Logger.LogError(
                ex,
                "Error al consultar entrenadores."
            );

            return Results.Problem(
                title: "Error al consultar entrenadores",
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


 // ============================================
 // ASIGNAR ENTRENADOR A CLIENTE - RECEPCION
 // ============================================


 // ============================================
 // ASIGNAR ENTRENADOR A CLIENTE - RECEPCION
 // CON AUDITORIA
 // ============================================

app.MapPut(
    "/api/clientes/{idCliente:int}/entrenador",
    async (
        int idCliente,
        AsignarEntrenadorRequest request,
        ClaimsPrincipal usuario,
        IConfiguration configuration
    ) =>
    {
        // =====================================
        // OBTENER USUARIO DESDE JWT
        // =====================================

        var sub = usuario.FindFirst("sub")?.Value;

        if (string.IsNullOrWhiteSpace(sub) ||
            !int.TryParse(sub, out var idUsuario) ||
            idUsuario <= 0)
        {
            return Results.Unauthorized();
        }

        // =====================================
        // VALIDAR CLIENTE
        // =====================================

        if (idCliente <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje = "El id del cliente no es válido."
            });
        }

        // =====================================
        // VALIDAR ENTRENADOR
        // =====================================

        if (request.IdEntrenador <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje = "El id del entrenador no es válido."
            });
        }

        var connectionString =
            configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            return Results.Problem(
                title: "Configuración faltante",
                detail: "No existe la conexión PostgreSQL.",
                statusCode: 500
            );
        }

        try
        {
            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            // =====================================
            // INICIAR TRANSACCION
            // =====================================

            await using var transaction =
                await connection.BeginTransactionAsync();

            // =====================================
            // CONFIGURAR USUARIO PARA AUDITORIA
            // =====================================

            await using (var auditCommand =
                new NpgsqlCommand(
                    """
                    SELECT set_config(
                        'gymflow.usuario_actual',
                        @usuario_actual,
                        true
                    );
                    """,
                    connection,
                    transaction
                ))
            {
                auditCommand.Parameters.AddWithValue(
                    "usuario_actual",
                    idUsuario.ToString()
                );

                await auditCommand.ExecuteScalarAsync();
            }

            // =====================================
            // VALIDAR ENTRENADOR ACTIVO
            // =====================================

            await using var entrenadorCommand =
                new NpgsqlCommand(
                    """
                    SELECT p.nombre_completo
                    FROM personal p
                    INNER JOIN usuarios u
                        ON u.id_usuario = p.id_usuario
                    INNER JOIN roles r
                        ON r.id_rol = u.id_rol
                    WHERE p.id_personal = @id_entrenador
                      AND r.nombre = 'Entrenador'
                      AND u.estatus = 'Activo';
                    """,
                    connection,
                    transaction
                );

            entrenadorCommand.Parameters.AddWithValue(
                "id_entrenador",
                request.IdEntrenador
            );

            var nombreEntrenador =
                await entrenadorCommand.ExecuteScalarAsync();

            if (nombreEntrenador is null ||
                nombreEntrenador == DBNull.Value)
            {
                return Results.NotFound(new
                {
                    mensaje =
                        "El entrenador no existe o está inactivo."
                });
            }

            // =====================================
            // ASIGNAR ENTRENADOR AL CLIENTE
            // =====================================

            await using var actualizarCommand =
                new NpgsqlCommand(
                    """
                    UPDATE clientes
                    SET id_entrenador = @id_entrenador
                    WHERE id_cliente = @id_cliente
                    RETURNING nombre_completo;
                    """,
                    connection,
                    transaction
                );

            actualizarCommand.Parameters.AddWithValue(
                "id_entrenador",
                request.IdEntrenador
            );

            actualizarCommand.Parameters.AddWithValue(
                "id_cliente",
                idCliente
            );

            var nombreCliente =
                await actualizarCommand.ExecuteScalarAsync();

            if (nombreCliente is null ||
                nombreCliente == DBNull.Value)
            {
                return Results.NotFound(new
                {
                    mensaje = "El cliente no existe."
                });
            }

            // =====================================
            // CONFIRMAR TRANSACCION
            // =====================================

            await transaction.CommitAsync();

            return Results.Ok(new
            {
                idCliente,
                nombreCliente = nombreCliente.ToString(),
                idEntrenador = request.IdEntrenador,
                nombreEntrenador = nombreEntrenador.ToString(),
                mensaje = "Entrenador asignado correctamente."
            });
        }
        catch (Exception ex)
        {
            app.Logger.LogError(
                ex,
                "Error al asignar entrenador al cliente {IdCliente}.",
                idCliente
            );

            return Results.Problem(
                title: "Error al asignar entrenador",
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


 // ============================================
 // QUITAR ENTRENADOR ASIGNADO - RECEPCION
 // ============================================

app.MapDelete(
    "/api/clientes/{idCliente:int}/entrenador",
    async (
        int idCliente,
        ClaimsPrincipal usuario,
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

        var sub = usuario.FindFirst("sub")?.Value;

        if (!int.TryParse(sub, out var idUsuario) ||
            idUsuario <= 0)
        {
            return Results.Unauthorized();
        }

        var connectionString =
            configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            return Results.Problem(
                title: "Configuración faltante",
                detail: "No existe la conexión PostgreSQL.",
                statusCode: 500
            );
        }

        try
        {
            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            await using var transaction =
                await connection.BeginTransactionAsync();

            // Obtener la asignación actual
            await using var clienteCommand =
                new NpgsqlCommand(
                    """
                    SELECT id_entrenador
                    FROM clientes
                    WHERE id_cliente = @id_cliente
                    FOR UPDATE;
                    """,
                    connection,
                    transaction
                );

            clienteCommand.Parameters.AddWithValue(
                "id_cliente",
                idCliente
            );

            var entrenadorActual =
                await clienteCommand.ExecuteScalarAsync();

            if (entrenadorActual is null)
            {
                return Results.NotFound(new
                {
                    mensaje = "El cliente no existe."
                });
            }

            if (entrenadorActual == DBNull.Value)
            {
                return Results.Ok(new
                {
                    idCliente,
                    idEntrenador = (int?)null,
                    mensaje = "El cliente ya no tiene entrenador asignado."
                });
            }

            // Identificar al recepcionista en auditoría
            await using var auditoriaCommand =
                new NpgsqlCommand(
                    """
                    SELECT set_config(
                        'gymflow.usuario_actual',
                        @usuario_actual,
                        true
                    );
                    """,
                    connection,
                    transaction
                );

            auditoriaCommand.Parameters.AddWithValue(
                "usuario_actual",
                idUsuario.ToString()
            );

            await auditoriaCommand.ExecuteScalarAsync();

            // Quitar solamente la asignación
            await using var actualizarCommand =
                new NpgsqlCommand(
                    """
                    UPDATE clientes
                    SET id_entrenador = NULL
                    WHERE id_cliente = @id_cliente;
                    """,
                    connection,
                    transaction
                );

            actualizarCommand.Parameters.AddWithValue(
                "id_cliente",
                idCliente
            );

            await actualizarCommand.ExecuteNonQueryAsync();

            await transaction.CommitAsync();

            return Results.Ok(new
            {
                idCliente,
                idEntrenador = (int?)null,
                mensaje = "Entrenador retirado correctamente."
            });
        }
        catch (Exception ex)
        {
            app.Logger.LogError(
                ex,
                "Error al retirar entrenador del cliente {IdCliente}.",
                idCliente
            );

            return Results.Problem(
                title: "Error al retirar entrenador",
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



app.Run();