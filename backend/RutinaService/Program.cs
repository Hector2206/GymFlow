using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Npgsql;
using RutinaService.Models;
using RutinaService.Services;

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
builder.Services.AddScoped<EntrenadorService>();

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
        if (string.IsNullOrWhiteSpace(request.Nombre))
        {
            return Results.BadRequest(new
            {
                mensaje = "El nombre del ejercicio es obligatorio."
            });
        }

        if (request.Nombre.Length > 120)
        {
            return Results.BadRequest(new
            {
                mensaje = "El nombre del ejercicio no puede superar los 120 caracteres."
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
                        descripcion,
                        imagen_url
                    )
                    VALUES (
                        @nombre,
                        @descripcion,
                        @imagen_url
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

            command.Parameters.AddWithValue(
                "imagen_url",
                NpgsqlTypes.NpgsqlDbType.Text,
                (object?)request.ImagenUrl ?? DBNull.Value
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
                    imagenUrl = request.ImagenUrl,
                    estado = true
                }
            );
        }
        catch (PostgresException ex)
        {
            app.Logger.LogError(
                ex,
                "Error PostgreSQL al registrar ejercicio."
            );

            return Results.BadRequest(new
            {
                mensaje =
                    "No se pudo registrar el ejercicio."
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
.RequireAuthorization(policy =>
{
    policy.RequireRole("Entrenador");
});

// ===============================
// LISTAR EJERCICIOS
// #907
// ===============================

app.MapGet(
    "/api/ejercicios",
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

        try
        {
            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            await using var command =
                new NpgsqlCommand(
                    """
                    SELECT
                        id_ejercicio,
                        nombre,
                        descripcion,
                        estado,
                        imagen_url
                    FROM ejercicios
                    ORDER BY nombre;
                    """,
                    connection
                );

            await using var reader =
                await command.ExecuteReaderAsync();

            var ejercicios =
                new List<object>();

            while (await reader.ReadAsync())
            {
                ejercicios.Add(new
                {
                    idEjercicio =
                        reader.GetInt32(0),

                    nombre =
                        reader.GetString(1),

                    descripcion =
                        reader.IsDBNull(2)
                            ? null
                            : reader.GetString(2),

                    estado =
                        reader.GetBoolean(3),

                    imagenUrl =
                        reader.IsDBNull(4)
                            ? null
                            : reader.GetString(4)
                });
            }

            return Results.Ok(ejercicios);
        }
        catch (Exception)
        {
            return Results.Problem(
                title: "Error al consultar ejercicios",
                detail: "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization();

// ===============================
// OBTENER EJERCICIO POR ID
// #908
// ===============================

app.MapGet(
    "/api/ejercicios/{idEjercicio:int}",
    async (
        int idEjercicio,
        IConfiguration configuration
    ) =>
    {
        if (idEjercicio <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje = "El id del ejercicio no es válido."
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

        try
        {
            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            await using var command =
                new NpgsqlCommand(
                    """
                    SELECT
                        id_ejercicio,
                        nombre,
                        descripcion,
                        estado,
                        imagen_url
                    FROM ejercicios
                    WHERE id_ejercicio = @id_ejercicio;
                    """,
                    connection
                );

            command.Parameters.AddWithValue(
                "id_ejercicio",
                idEjercicio
            );

            await using var reader =
                await command.ExecuteReaderAsync();

            if (!await reader.ReadAsync())
            {
                return Results.NotFound(new
                {
                    mensaje = "El ejercicio no existe."
                });
            }

            return Results.Ok(new
            {
                idEjercicio =
                    reader.GetInt32(0),

                nombre =
                    reader.GetString(1),

                descripcion =
                    reader.IsDBNull(2)
                        ? null
                        : reader.GetString(2),

                estado =
                    reader.GetBoolean(3),

                imagenUrl =
                    reader.IsDBNull(4)
                        ? null
                        : reader.GetString(4)
            });
        }
        catch (Exception)
        {
            return Results.Problem(
                title: "Error al consultar ejercicio",
                detail: "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization();

// ===============================
// EDITAR EJERCICIO
// #909
// ===============================

app.MapPut(
    "/api/ejercicios/{idEjercicio:int}",
    async (
        int idEjercicio,
        EditarEjercicioRequest request,
        IConfiguration configuration
    ) =>
    {
        if (idEjercicio <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje = "El id del ejercicio no es válido."
            });
        }

        if (string.IsNullOrWhiteSpace(request.Nombre))
        {
            return Results.BadRequest(new
            {
                mensaje = "El nombre del ejercicio es obligatorio."
            });
        }

        if (request.Nombre.Length > 120)
        {
            return Results.BadRequest(new
            {
                mensaje = "El nombre del ejercicio no puede superar los 120 caracteres."
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

        try
        {
            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            await using var command =
                new NpgsqlCommand(
                   """
                    UPDATE ejercicios
                    SET
                        nombre = @nombre,
                        descripcion = @descripcion,
                        imagen_url = CASE
                            WHEN @actualizar_imagen THEN @imagen_url
                            ELSE imagen_url
                        END,
                        estado = COALESCE(@estado, estado)
                    WHERE id_ejercicio = @id_ejercicio
                    RETURNING imagen_url, estado;
                    """,
                    connection
                );

            command.Parameters.AddWithValue(
                "id_ejercicio",
                idEjercicio
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

            command.Parameters.AddWithValue(
                "imagen_url",
                NpgsqlTypes.NpgsqlDbType.Text,
                (object?)request.ImagenUrl ?? DBNull.Value
            );

            command.Parameters.AddWithValue(
                "actualizar_imagen",
                request.ImagenUrlEspecificada
            );

            command.Parameters.AddWithValue(
                "estado",
                NpgsqlTypes.NpgsqlDbType.Boolean,
                (object?)request.Estado ?? DBNull.Value
            );

            await using var reader =
                await command.ExecuteReaderAsync();

            if (!await reader.ReadAsync())
            {
                return Results.NotFound(new
                {
                    mensaje = "El ejercicio no existe."
                });
            }

            var imagenGuardada =
                reader.IsDBNull(0)
                    ? null
                    : reader.GetString(0);

            var estadoGuardado =
                reader.GetBoolean(1);

            return Results.Ok(new
            {
                idEjercicio,
                nombre = request.Nombre,
                descripcion = request.Descripcion,
                imagenUrl = imagenGuardada,
                estado = estadoGuardado,
                mensaje = "Ejercicio actualizado correctamente."
            });
        }
        catch (PostgresException ex)
        {
            app.Logger.LogError(
                ex,
                "Error PostgreSQL al actualizar ejercicio."
            );

            return Results.BadRequest(new
            {
                mensaje =
                    "No se pudo actualizar el ejercicio."
            });
        }
        catch (Exception)
        {
            return Results.Problem(
                title: "Error al actualizar ejercicio",
                detail: "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Entrenador");
});

// ===============================
// DESACTIVAR EJERCICIO
// #910
// ===============================

app.MapDelete(
    "/api/ejercicios/{idEjercicio:int}",
    async (
        int idEjercicio,
        IConfiguration configuration
    ) =>
    {
        if (idEjercicio <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje = "El id del ejercicio no es válido."
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

        try
        {
            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            await using var command =
                new NpgsqlCommand(
                    """
                    UPDATE ejercicios
                    SET estado = FALSE
                    WHERE id_ejercicio = @id_ejercicio;
                    """,
                    connection
                );

            command.Parameters.AddWithValue(
                "id_ejercicio",
                idEjercicio
            );

            var filasAfectadas =
                await command.ExecuteNonQueryAsync();

            if (filasAfectadas == 0)
            {
                return Results.NotFound(new
                {
                    mensaje = "El ejercicio no existe."
                });
            }

            return Results.Ok(new
            {
                idEjercicio,
                estado = false,
                mensaje = "Ejercicio desactivado correctamente."
            });
        }
        catch (Exception)
        {
            return Results.Problem(
                title: "Error al desactivar ejercicio",
                detail: "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Entrenador");
});


// ===============================
// BUSCAR EJERCICIO POR NOMBRE
// #911
// ===============================

app.MapGet(
    "/api/ejercicios/buscar",
    async (
        string nombre,
        IConfiguration configuration
    ) =>
    {
        if (string.IsNullOrWhiteSpace(nombre))
        {
            return Results.BadRequest(new
            {
                mensaje = "El nombre de búsqueda es obligatorio."
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

        try
        {
            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            await using var command =
                new NpgsqlCommand(
                    """
                    SELECT
                        id_ejercicio,
                        nombre,
                        descripcion,
                        estado,
                        imagen_url
                    FROM ejercicios
                    WHERE nombre ILIKE @nombre
                    ORDER BY nombre;
                    """,
                    connection
                );

            command.Parameters.AddWithValue(
                "nombre",
                $"%{nombre}%"
            );

            await using var reader =
                await command.ExecuteReaderAsync();

            var ejercicios =
                new List<object>();

            while (await reader.ReadAsync())
            {
                ejercicios.Add(new
                {
                    idEjercicio =
                        reader.GetInt32(0),

                    nombre =
                        reader.GetString(1),

                    descripcion =
                        reader.IsDBNull(2)
                            ? null
                            : reader.GetString(2),

                    estado =
                        reader.GetBoolean(3),

                    imagenUrl =
                        reader.IsDBNull(4)
                            ? null
                            : reader.GetString(4)
                });
            }

            return Results.Ok(ejercicios);
        }
        catch (Exception)
        {
            return Results.Problem(
                title: "Error al buscar ejercicios",
                detail: "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization();


// ===============================
// CREAR RUTINA
// #913 + #914 + #915 + #916 + #917
// #918 + #919 + #920
// #1281 + #1282
// ===============================

app.MapPost(
    "/api/rutinas",
    async (
        CrearRutinaRequest request,
        ClaimsPrincipal usuario,
        EntrenadorService entrenadorService,
        IConfiguration configuration
    ) =>
    {
        if (request.IdCliente <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "El id del cliente no es válido."
            });
        }

        if (string.IsNullOrWhiteSpace(request.Nombre))
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "El nombre de la rutina es obligatorio."
            });
        }

        if (request.Dias is null ||
            request.Dias.Count == 0)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "La rutina debe tener al menos un día de entrenamiento."
            });
        }

        foreach (var dia in request.Dias)
        {
            if (string.IsNullOrWhiteSpace(dia.Dia))
            {
                return Results.BadRequest(new
                {
                    mensaje =
                        "El nombre del día es obligatorio."
                });
            }

            if (dia.Ejercicios is null ||
                dia.Ejercicios.Count == 0)
            {
                return Results.BadRequest(new
                {
                    mensaje =
                        $"El día {dia.Dia} debe tener al menos un ejercicio."
                });
            }

            foreach (var ejercicio in dia.Ejercicios)
            {
                if (ejercicio.IdEjercicio <= 0)
                {
                    return Results.BadRequest(new
                    {
                        mensaje =
                            "El id del ejercicio no es válido."
                    });
                }

                if (ejercicio.Series <= 0)
                {
                    return Results.BadRequest(new
                    {
                        mensaje =
                            "La cantidad de series debe ser mayor a 0."
                    });
                }

                if (ejercicio.Repeticiones <= 0)
                {
                    return Results.BadRequest(new
                    {
                        mensaje =
                            "La cantidad de repeticiones debe ser mayor a 0."
                    });
                }

                if (ejercicio.Orden <= 0)
                {
                    return Results.BadRequest(new
                    {
                        mensaje =
                            "El orden del ejercicio debe ser mayor a 0."
                    });
                }
            }
        }

        var idEntrenador =
            await entrenadorService.ObtenerIdPersonalAsync(
                usuario
            );

        if (idEntrenador is null)
        {
            return Results.NotFound(new
            {
                mensaje =
                    "No se encontró información del entrenador."
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

        try
        {
            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            await using var transaction =
                await connection.BeginTransactionAsync();

            await using var clienteCommand =
                new NpgsqlCommand(
                    """
                    SELECT COUNT(*)
                    FROM clientes
                    WHERE id_cliente = @id_cliente
                      AND id_entrenador = @id_entrenador;
                    """,
                    connection,
                    transaction
                );

            clienteCommand.Parameters.AddWithValue(
                "id_cliente",
                request.IdCliente
            );

            clienteCommand.Parameters.AddWithValue(
                "id_entrenador",
                idEntrenador.Value
            );

            var clienteAsignado =
                Convert.ToInt32(
                    await clienteCommand.ExecuteScalarAsync()
                ) > 0;

            if (!clienteAsignado)
            {
                return Results.Json(
                    new
                    {
                        mensaje =
                            "Acceso denegado. El cliente no está asignado al entrenador autenticado."
                    },
                    statusCode:
                        StatusCodes.Status403Forbidden
                );
            }

            await using var command =
                new NpgsqlCommand(
                    """
                    INSERT INTO rutinas (
                        nombre,
                        descripcion,
                        id_cliente
                    )
                    VALUES (
                        @nombre,
                        @descripcion,
                        @id_cliente
                    )
                    RETURNING id_rutina;
                    """,
                    connection,
                    transaction
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

            command.Parameters.AddWithValue(
                "id_cliente",
                request.IdCliente
            );

            var idRutina =
                Convert.ToInt32(
                    await command.ExecuteScalarAsync()
                );

            var diasGuardados =
                new List<object>();

            foreach (var dia in request.Dias)
            {
                await using var diaCommand =
                    new NpgsqlCommand(
                        """
                        INSERT INTO dias_rutina (
                            dia,
                            id_rutina
                        )
                        VALUES (
                            @dia,
                            @id_rutina
                        )
                        RETURNING id_dia;
                        """,
                        connection,
                        transaction
                    );

                diaCommand.Parameters.AddWithValue(
                    "dia",
                    dia.Dia
                );

                diaCommand.Parameters.AddWithValue(
                    "id_rutina",
                    idRutina
                );

                var idDia =
                    Convert.ToInt32(
                        await diaCommand.ExecuteScalarAsync()
                    );

                var ejerciciosGuardados =
                    new List<object>();

                foreach (var ejercicio in dia.Ejercicios)
                {
                    await using var ejercicioCommand =
                        new NpgsqlCommand(
                            """
                            INSERT INTO ejercicios_rutina (
                                id_dia,
                                id_ejercicio,
                                series,
                                repeticiones,
                                orden
                            )
                            VALUES (
                                @id_dia,
                                @id_ejercicio,
                                @series,
                                @repeticiones,
                                @orden
                            )
                            RETURNING id_ejercicio_rutina;
                            """,
                            connection,
                            transaction
                        );

                    ejercicioCommand.Parameters.AddWithValue(
                        "id_dia",
                        idDia
                    );

                    ejercicioCommand.Parameters.AddWithValue(
                        "id_ejercicio",
                        ejercicio.IdEjercicio
                    );

                    ejercicioCommand.Parameters.AddWithValue(
                        "series",
                        ejercicio.Series
                    );

                    ejercicioCommand.Parameters.AddWithValue(
                        "repeticiones",
                        ejercicio.Repeticiones
                    );

                    ejercicioCommand.Parameters.AddWithValue(
                        "orden",
                        ejercicio.Orden
                    );

                    var idEjercicioRutina =
                        Convert.ToInt32(
                            await ejercicioCommand.ExecuteScalarAsync()
                        );

                    ejerciciosGuardados.Add(new
                    {
                        idEjercicioRutina,
                        idEjercicio =
                            ejercicio.IdEjercicio,
                        series =
                            ejercicio.Series,
                        repeticiones =
                            ejercicio.Repeticiones,
                        orden =
                            ejercicio.Orden
                    });
                }

                diasGuardados.Add(new
                {
                    idDia,
                    dia = dia.Dia,
                    ejercicios =
                        ejerciciosGuardados
                });
            }

            await transaction.CommitAsync();

            return Results.Created(
                $"/api/rutinas/{idRutina}",
                new
                {
                    idRutina,
                    idCliente =
                        request.IdCliente,
                    idEntrenador =
                        idEntrenador.Value,
                    nombre =
                        request.Nombre,
                    descripcion =
                        request.Descripcion,
                    dias =
                        diasGuardados
                }
            );
        }
        catch (PostgresException ex)
        {
            app.Logger.LogError(
                ex,
                "Error PostgreSQL al registrar rutina."
            );

            return Results.BadRequest(new
            {
                mensaje =
                    "No se pudo registrar la rutina."
            });
        }
        catch (Exception)
        {
            return Results.Problem(
                title:
                    "Error al registrar rutina",
                detail:
                    "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Entrenador");
});


// ===============================
// EDITAR RUTINA
// #921 + #1281 + #1283 + #1284
// ===============================

app.MapPut(
    "/api/rutinas/{idRutina:int}",
    async (
        int idRutina,
        CrearRutinaRequest request,
        ClaimsPrincipal usuario,
        EntrenadorService entrenadorService,
        IConfiguration configuration
    ) =>
    {
        if (idRutina <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "El id de la rutina no es válido."
            });
        }

        if (request.IdCliente <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "El id del cliente no es válido."
            });
        }

        if (string.IsNullOrWhiteSpace(request.Nombre))
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "El nombre de la rutina es obligatorio."
            });
        }

        if (request.Dias is null ||
            request.Dias.Count == 0)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "La rutina debe tener al menos un día de entrenamiento."
            });
        }

        foreach (var dia in request.Dias)
        {
            if (string.IsNullOrWhiteSpace(dia.Dia))
            {
                return Results.BadRequest(new
                {
                    mensaje =
                        "El nombre del día es obligatorio."
                });
            }

            if (dia.Ejercicios is null ||
                dia.Ejercicios.Count == 0)
            {
                return Results.BadRequest(new
                {
                    mensaje =
                        $"El día {dia.Dia} debe tener al menos un ejercicio."
                });
            }

            foreach (var ejercicio in dia.Ejercicios)
            {
                if (ejercicio.IdEjercicio <= 0)
                {
                    return Results.BadRequest(new
                    {
                        mensaje =
                            "El id del ejercicio no es válido."
                    });
                }

                if (ejercicio.Series <= 0)
                {
                    return Results.BadRequest(new
                    {
                        mensaje =
                            "La cantidad de series debe ser mayor a 0."
                    });
                }

                if (ejercicio.Repeticiones <= 0)
                {
                    return Results.BadRequest(new
                    {
                        mensaje =
                            "La cantidad de repeticiones debe ser mayor a 0."
                    });
                }

                if (ejercicio.Orden <= 0)
                {
                    return Results.BadRequest(new
                    {
                        mensaje =
                            "El orden del ejercicio debe ser mayor a 0."
                    });
                }
            }
        }

        var idEntrenador =
            await entrenadorService.ObtenerIdPersonalAsync(
                usuario
            );

        if (idEntrenador is null)
        {
            return Results.NotFound(new
            {
                mensaje =
                    "No se encontró información del entrenador."
            });
        }

        var connectionString =
            configuration.GetConnectionString(
                "PostgreSQL"
            );

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            return Results.Problem(
                title:
                    "Configuración faltante",
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

            await using var transaction =
                await connection.BeginTransactionAsync();

            // ===============================
            // VALIDAR QUE LA RUTINA PERTENEZCA
            // A UN CLIENTE DEL ENTRENADOR
            // #1283 + #1284
            // ===============================

            await using var rutinaCommand =
                new NpgsqlCommand(
                    """
                    SELECT COUNT(*)
                    FROM rutinas r
                    INNER JOIN clientes c
                        ON c.id_cliente = r.id_cliente
                    WHERE r.id_rutina = @id_rutina
                      AND c.id_entrenador = @id_entrenador;
                    """,
                    connection,
                    transaction
                );

            rutinaCommand.Parameters.AddWithValue(
                "id_rutina",
                idRutina
            );

            rutinaCommand.Parameters.AddWithValue(
                "id_entrenador",
                idEntrenador.Value
            );

            var rutinaAsignada =
                Convert.ToInt32(
                    await rutinaCommand.ExecuteScalarAsync()
                ) > 0;

            if (!rutinaAsignada)
            {
                return Results.Json(
                    new
                    {
                        mensaje =
                            "Acceso denegado. La rutina no pertenece a un cliente asignado al entrenador autenticado."
                    },
                    statusCode:
                        StatusCodes.Status403Forbidden
                );
            }

            // ===============================
            // VALIDAR CLIENTE DESTINO
            // #1283 + #1284
            // ===============================

            await using var clienteCommand =
                new NpgsqlCommand(
                    """
                    SELECT COUNT(*)
                    FROM clientes
                    WHERE id_cliente = @id_cliente
                      AND id_entrenador = @id_entrenador;
                    """,
                    connection,
                    transaction
                );

            clienteCommand.Parameters.AddWithValue(
                "id_cliente",
                request.IdCliente
            );

            clienteCommand.Parameters.AddWithValue(
                "id_entrenador",
                idEntrenador.Value
            );

            var clienteAsignado =
                Convert.ToInt32(
                    await clienteCommand.ExecuteScalarAsync()
                ) > 0;

            if (!clienteAsignado)
            {
                return Results.Json(
                    new
                    {
                        mensaje =
                            "Acceso denegado. El cliente no está asignado al entrenador autenticado."
                    },
                    statusCode:
                        StatusCodes.Status403Forbidden
                );
            }

            // ===============================
            // ACTUALIZAR RUTINA
            // ===============================

            await using var command =
                new NpgsqlCommand(
                    """
                    UPDATE rutinas
                    SET
                        nombre = @nombre,
                        descripcion = @descripcion,
                        id_cliente = @id_cliente
                    WHERE id_rutina = @id_rutina;
                    """,
                    connection,
                    transaction
                );

            command.Parameters.AddWithValue(
                "id_rutina",
                idRutina
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

            command.Parameters.AddWithValue(
                "id_cliente",
                request.IdCliente
            );

            var filasAfectadas =
                await command.ExecuteNonQueryAsync();

            if (filasAfectadas == 0)
            {
                return Results.NotFound(new
                {
                    mensaje =
                        "La rutina no existe."
                });
            }
            // ===============================
            // ELIMINAR DETALLE ACTUAL
            // ===============================

            await using var eliminarEjerciciosCommand =
                new NpgsqlCommand(
                    """
                    DELETE FROM ejercicios_rutina
                    WHERE id_dia IN (
                        SELECT id_dia
                        FROM dias_rutina
                        WHERE id_rutina = @id_rutina
                    );
                    """,
                    connection,
                    transaction
                );

            eliminarEjerciciosCommand.Parameters.AddWithValue(
                "id_rutina",
                idRutina
            );

            await eliminarEjerciciosCommand.ExecuteNonQueryAsync();

            await using var eliminarDiasCommand =
                new NpgsqlCommand(
                    """
                    DELETE FROM dias_rutina
                    WHERE id_rutina = @id_rutina;
                    """,
                    connection,
                    transaction
                );

            eliminarDiasCommand.Parameters.AddWithValue(
                "id_rutina",
                idRutina
            );

            await eliminarDiasCommand.ExecuteNonQueryAsync();

            // ===============================
            // CREAR NUEVAMENTE LOS DÍAS
            // ===============================

            foreach (var dia in request.Dias)
            {
                await using var diaCommand =
                    new NpgsqlCommand(
                        """
                        INSERT INTO dias_rutina (
                            dia,
                            id_rutina
                        )
                        VALUES (
                            @dia,
                            @id_rutina
                        )
                        RETURNING id_dia;
                        """,
                        connection,
                        transaction
                    );

                diaCommand.Parameters.AddWithValue(
                    "dia",
                    dia.Dia
                );

                diaCommand.Parameters.AddWithValue(
                    "id_rutina",
                    idRutina
                );

                var idDia =
                    Convert.ToInt32(
                        await diaCommand.ExecuteScalarAsync()
                    );

                // ===============================
                // CREAR NUEVAMENTE LOS EJERCICIOS
                // ===============================

                foreach (var ejercicio in dia.Ejercicios)
                {
                    await using var ejercicioCommand =
                        new NpgsqlCommand(
                            """
                            INSERT INTO ejercicios_rutina (
                                id_dia,
                                id_ejercicio,
                                series,
                                repeticiones,
                                orden
                            )
                            VALUES (
                                @id_dia,
                                @id_ejercicio,
                                @series,
                                @repeticiones,
                                @orden
                            );
                            """,
                            connection,
                            transaction
                        );

                    ejercicioCommand.Parameters.AddWithValue(
                        "id_dia",
                        idDia
                    );

                    ejercicioCommand.Parameters.AddWithValue(
                        "id_ejercicio",
                        ejercicio.IdEjercicio
                    );

                    ejercicioCommand.Parameters.AddWithValue(
                        "series",
                        ejercicio.Series
                    );

                    ejercicioCommand.Parameters.AddWithValue(
                        "repeticiones",
                        ejercicio.Repeticiones
                    );

                    ejercicioCommand.Parameters.AddWithValue(
                        "orden",
                        ejercicio.Orden
                    );

                    await ejercicioCommand.ExecuteNonQueryAsync();
                }
            }
            await transaction.CommitAsync();


            return Results.Ok(new
            {
                idRutina,
                idCliente =
                    request.IdCliente,
                idEntrenador =
                    idEntrenador.Value,
                nombre =
                    request.Nombre,
                descripcion =
                    request.Descripcion,
                mensaje =
                    "Rutina actualizada correctamente."
            });
        }
        catch (PostgresException ex)
        {
            app.Logger.LogError(
                ex,
                "Error PostgreSQL al actualizar rutina."
            );

            return Results.BadRequest(new
            {
                mensaje =
                    "No se pudo actualizar la rutina."
            });
        }
        catch (Exception)
        {
            return Results.Problem(
                title:
                    "Error al actualizar rutina",
                detail:
                    "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Entrenador");
});

// ===============================
// ELIMINAR RUTINA
// ===============================

app.MapDelete(
    "/api/rutinas/{idRutina:int}",
    async (
        int idRutina,
        ClaimsPrincipal usuario,
        EntrenadorService entrenadorService,
        IConfiguration configuration
    ) =>
    {
        if (idRutina <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "El id de la rutina no es válido."
            });
        }

        var idEntrenador =
            await entrenadorService.ObtenerIdPersonalAsync(
                usuario
            );

        if (idEntrenador is null)
        {
            return Results.NotFound(new
            {
                mensaje =
                    "No se encontró información del entrenador."
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

        try
        {
            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            await using var transaction =
                await connection.BeginTransactionAsync();

            // ===============================
            // VALIDAR EXISTENCIA Y PERTENENCIA
            // ===============================

            await using var validarCommand =
                new NpgsqlCommand(
                    """
                    SELECT
                        EXISTS (
                            SELECT 1
                            FROM rutinas
                            WHERE id_rutina = @id_rutina
                        ),
                        EXISTS (
                            SELECT 1
                            FROM rutinas r
                            INNER JOIN clientes c
                                ON c.id_cliente = r.id_cliente
                            WHERE r.id_rutina = @id_rutina
                              AND c.id_entrenador = @id_entrenador
                        );
                    """,
                    connection,
                    transaction
                );

            validarCommand.Parameters.AddWithValue(
                "id_rutina",
                idRutina
            );

            validarCommand.Parameters.AddWithValue(
                "id_entrenador",
                idEntrenador.Value
            );

            bool existe;
            bool pertenece;

            await using (
                var reader =
                    await validarCommand.ExecuteReaderAsync()
            )
            {
                await reader.ReadAsync();

                existe =
                    reader.GetBoolean(0);

                pertenece =
                    reader.GetBoolean(1);
            }

            if (!existe)
            {
                return Results.NotFound(new
                {
                    mensaje =
                        "La rutina no existe."
                });
            }

            if (!pertenece)
            {
                return Results.Json(
                    new
                    {
                        mensaje =
                            "Acceso denegado. La rutina no pertenece a un cliente asignado al entrenador autenticado."
                    },
                    statusCode:
                        StatusCodes.Status403Forbidden
                );
            }

            // ===============================
            // ELIMINAR EJERCICIOS DE LA RUTINA
            // ===============================

            await using var eliminarEjerciciosCommand =
                new NpgsqlCommand(
                    """
                    DELETE FROM ejercicios_rutina
                    WHERE id_dia IN (
                        SELECT id_dia
                        FROM dias_rutina
                        WHERE id_rutina = @id_rutina
                    );
                    """,
                    connection,
                    transaction
                );

            eliminarEjerciciosCommand.Parameters.AddWithValue(
                "id_rutina",
                idRutina
            );

            await eliminarEjerciciosCommand.ExecuteNonQueryAsync();

            // ===============================
            // ELIMINAR DÍAS
            // ===============================

            await using var eliminarDiasCommand =
                new NpgsqlCommand(
                    """
                    DELETE FROM dias_rutina
                    WHERE id_rutina = @id_rutina;
                    """,
                    connection,
                    transaction
                );

            eliminarDiasCommand.Parameters.AddWithValue(
                "id_rutina",
                idRutina
            );

            await eliminarDiasCommand.ExecuteNonQueryAsync();

            // ===============================
            // ELIMINAR RUTINA
            // ===============================

            await using var eliminarRutinaCommand =
                new NpgsqlCommand(
                    """
                    DELETE FROM rutinas
                    WHERE id_rutina = @id_rutina;
                    """,
                    connection,
                    transaction
                );

            eliminarRutinaCommand.Parameters.AddWithValue(
                "id_rutina",
                idRutina
            );

            await eliminarRutinaCommand.ExecuteNonQueryAsync();

            await transaction.CommitAsync();

            return Results.Ok(new
            {
                idRutina,
                mensaje =
                    "Rutina eliminada correctamente."
            });
        }
        catch (PostgresException ex)
        {
            app.Logger.LogError(
                ex,
                "Error PostgreSQL al eliminar rutina."
            );

            return Results.BadRequest(new
            {
                mensaje =
                    "No se pudo eliminar la rutina."
            });
        }
        catch (Exception)
        {
            return Results.Problem(
                title:
                    "Error al eliminar rutina",
                detail:
                    "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Entrenador");
});

// ===============================
// LISTAR RUTINAS
// #922
// ===============================

app.MapGet(
    "/api/rutinas",
    async (
        ClaimsPrincipal usuario,
        EntrenadorService entrenadorService,
        IConfiguration configuration
    ) =>
    {
        var idEntrenador =
            await entrenadorService.ObtenerIdPersonalAsync(
                usuario
            );

        if (idEntrenador is null)
        {
            return Results.NotFound(new
            {
                mensaje =
                    "No se encontró información del entrenador."
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

        try
        {
            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            await using var command =
                new NpgsqlCommand(
                    """
                    SELECT
                        r.id_rutina,
                        r.nombre,
                        r.descripcion,
                        r.id_cliente,
                        c.nombre_completo
                    FROM rutinas r
                    INNER JOIN clientes c
                        ON c.id_cliente = r.id_cliente
                    WHERE c.id_entrenador = @id_entrenador
                    ORDER BY r.id_rutina DESC;
                    """,
                    connection
                );

            command.Parameters.AddWithValue(
                "id_entrenador",
                idEntrenador.Value
            );

            await using var reader =
                await command.ExecuteReaderAsync();

            var rutinas =
                new List<object>();

            while (await reader.ReadAsync())
            {
                rutinas.Add(new
                {
                    idRutina =
                        reader.GetInt32(0),

                    nombre =
                        reader.GetString(1),

                    descripcion =
                        reader.IsDBNull(2)
                            ? null
                            : reader.GetString(2),

                    idCliente =
                        reader.GetInt32(3),

                    nombreCliente =
                        reader.GetString(4)
                });
            }

            return Results.Ok(rutinas);
        }
        catch (Exception)
        {
            return Results.Problem(
                title: "Error al consultar rutinas",
                detail: "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Entrenador");
});


// ===============================
// OBTENER RUTINA POR ID
// #923
// ===============================

app.MapGet(
    "/api/rutinas/{idRutina:int}",
    async (
        int idRutina,
        ClaimsPrincipal usuario,
        EntrenadorService entrenadorService,
        IConfiguration configuration
    ) =>
    {
        if (idRutina <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "El id de la rutina no es válido."
            });
        }

        var idEntrenador =
            await entrenadorService.ObtenerIdPersonalAsync(
                usuario
            );

        if (idEntrenador is null)
        {
            return Results.NotFound(new
            {
                mensaje =
                    "No se encontró información del entrenador."
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

        try
        {
            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            await using var validarCommand =
                new NpgsqlCommand(
                    """
                    SELECT
                        EXISTS (
                            SELECT 1
                            FROM rutinas
                            WHERE id_rutina = @id_rutina
                        ),
                        EXISTS (
                            SELECT 1
                            FROM rutinas r
                            INNER JOIN clientes c
                                ON c.id_cliente = r.id_cliente
                            WHERE r.id_rutina = @id_rutina
                              AND c.id_entrenador = @id_entrenador
                        );
                    """,
                    connection
                );

            validarCommand.Parameters.AddWithValue(
                "id_rutina",
                idRutina
            );

            validarCommand.Parameters.AddWithValue(
                "id_entrenador",
                idEntrenador.Value
            );

            bool existe;
            bool pertenece;

            await using (
                var validarReader =
                    await validarCommand.ExecuteReaderAsync()
            )
            {
                await validarReader.ReadAsync();

                existe =
                    validarReader.GetBoolean(0);

                pertenece =
                    validarReader.GetBoolean(1);
            }

            if (!existe)
            {
                return Results.NotFound(new
                {
                    mensaje =
                        "La rutina no existe."
                });
            }

            if (!pertenece)
            {
                return Results.Json(
                    new
                    {
                        mensaje =
                            "Acceso denegado. La rutina no pertenece a un cliente asignado al entrenador autenticado."
                    },
                    statusCode:
                        StatusCodes.Status403Forbidden
                );
            }

            await using var rutinaCommand =
                new NpgsqlCommand(
                    """
                    SELECT
                        r.id_rutina,
                        r.nombre,
                        r.descripcion,
                        r.id_cliente,
                        c.nombre_completo
                    FROM rutinas r
                    INNER JOIN clientes c
                        ON c.id_cliente = r.id_cliente
                    WHERE r.id_rutina = @id_rutina;
                    """,
                    connection
                );

            rutinaCommand.Parameters.AddWithValue(
                "id_rutina",
                idRutina
            );

            int idCliente;
            string nombreRutina;
            string? descripcion;
            string nombreCliente;

            await using (var rutinaReader =
                await rutinaCommand.ExecuteReaderAsync())
            {
                if (!await rutinaReader.ReadAsync())
                {
                    return Results.NotFound(new
                    {
                        mensaje =
                            "La rutina no existe."
                    });
                }

                nombreRutina =
                    rutinaReader.GetString(1);

                descripcion =
                    rutinaReader.IsDBNull(2)
                        ? null
                        : rutinaReader.GetString(2);

                idCliente =
                    rutinaReader.GetInt32(3);

                nombreCliente =
                    rutinaReader.GetString(4);
            }

            await using var detalleCommand =
                new NpgsqlCommand(
                    """
                    SELECT
                        d.id_dia,
                        d.dia,
                        er.id_ejercicio_rutina,
                        er.id_ejercicio,
                        e.nombre,
                        e.descripcion,
                        er.series,
                        er.repeticiones,
                        er.orden,
                        e.imagen_url
                    FROM dias_rutina d
                    LEFT JOIN ejercicios_rutina er
                        ON er.id_dia = d.id_dia
                    LEFT JOIN ejercicios e
                        ON e.id_ejercicio = er.id_ejercicio
                    WHERE d.id_rutina = @id_rutina
                    ORDER BY
                        d.id_dia,
                        er.orden;
                    """,
                    connection
                );

            detalleCommand.Parameters.AddWithValue(
                "id_rutina",
                idRutina
            );

            var dias =
                new Dictionary<
                    int,
                    (string Dia, List<object> Ejercicios)
                >();

            await using var detalleReader =
                await detalleCommand.ExecuteReaderAsync();

            while (await detalleReader.ReadAsync())
            {
                var idDia =
                    detalleReader.GetInt32(0);

                var dia =
                    detalleReader.GetString(1);

                if (!dias.ContainsKey(idDia))
                {
                    dias[idDia] =
                        (dia, new List<object>());
                }

                if (!detalleReader.IsDBNull(2))
                {
                    dias[idDia].Ejercicios.Add(new
                    {
                        idEjercicioRutina =
                            detalleReader.GetInt32(2),

                        idEjercicio =
                            detalleReader.GetInt32(3),

                        nombre =
                            detalleReader.GetString(4),

                        descripcion =
                            detalleReader.IsDBNull(5)
                                ? null
                                : detalleReader.GetString(5),

                        series =
                            detalleReader.GetInt32(6),

                        repeticiones =
                            detalleReader.GetInt32(7),

                        orden =
                            detalleReader.GetInt32(8),

                        imagenUrl =
                            detalleReader.IsDBNull(9)
                                ? null
                                : detalleReader.GetString(9)
                    });
                }
            }

            var diasRespuesta =
                dias.Select(d => new
                {
                    idDia = d.Key,
                    dia = d.Value.Dia,
                    ejercicios =
                        d.Value.Ejercicios
                })
                .ToList();

            return Results.Ok(new
            {
                idRutina,
                idCliente,
                nombreCliente,
                nombre = nombreRutina,
                descripcion,
                dias = diasRespuesta
            });
        }
        catch (Exception)
        {
            return Results.Problem(
                title:
                    "Error al consultar rutina",
                detail:
                    "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Entrenador");
});

// ===============================
// OBTENER RUTINAS POR CLIENTE
// #924
// ===============================

app.MapGet(
    "/api/rutinas/cliente/{idCliente:int}",
    async (
        int idCliente,
        ClaimsPrincipal usuario,
        EntrenadorService entrenadorService,
        IConfiguration configuration
    ) =>
    {
        if (idCliente <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "El id del cliente no es válido."
            });
        }

        var idEntrenador =
            await entrenadorService.ObtenerIdPersonalAsync(
                usuario
            );

        if (idEntrenador is null)
        {
            return Results.NotFound(new
            {
                mensaje =
                    "No se encontró información del entrenador."
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

        try
        {
            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            await using var validarClienteCommand =
                new NpgsqlCommand(
                    """
                    SELECT
                        EXISTS (
                            SELECT 1
                            FROM clientes
                            WHERE id_cliente = @id_cliente
                        ),
                        EXISTS (
                            SELECT 1
                            FROM clientes
                            WHERE id_cliente = @id_cliente
                              AND id_entrenador = @id_entrenador
                        );
                    """,
                    connection
                );

            validarClienteCommand.Parameters.AddWithValue(
                "id_cliente",
                idCliente
            );

            validarClienteCommand.Parameters.AddWithValue(
                "id_entrenador",
                idEntrenador.Value
            );

            bool existeCliente;
            bool perteneceCliente;

            await using (
                var validarReader =
                    await validarClienteCommand.ExecuteReaderAsync()
            )
            {
                await validarReader.ReadAsync();

                existeCliente =
                    validarReader.GetBoolean(0);

                perteneceCliente =
                    validarReader.GetBoolean(1);
            }

            if (!existeCliente)
            {
                return Results.NotFound(new
                {
                    mensaje =
                        "El cliente no existe."
                });
            }

            if (!perteneceCliente)
            {
                return Results.Json(
                    new
                    {
                        mensaje =
                            "Acceso denegado. El cliente no está asignado al entrenador autenticado."
                    },
                    statusCode:
                        StatusCodes.Status403Forbidden
                );
            }

            await using var command =
                new NpgsqlCommand(
                    """
                    SELECT
                        r.id_rutina,
                        r.nombre,
                        r.descripcion,
                        r.id_cliente,
                        c.nombre_completo
                    FROM rutinas r
                    INNER JOIN clientes c
                        ON c.id_cliente = r.id_cliente
                    WHERE r.id_cliente = @id_cliente
                    ORDER BY r.id_rutina DESC;
                    """,
                    connection
                );

            command.Parameters.AddWithValue(
                "id_cliente",
                idCliente
            );

            await using var reader =
                await command.ExecuteReaderAsync();

            var rutinas =
                new List<object>();

            while (await reader.ReadAsync())
            {
                rutinas.Add(new
                {
                    idRutina =
                        reader.GetInt32(0),

                    nombre =
                        reader.GetString(1),

                    descripcion =
                        reader.IsDBNull(2)
                            ? null
                            : reader.GetString(2),

                    idCliente =
                        reader.GetInt32(3),

                    nombreCliente =
                        reader.GetString(4)
                });
            }

            return Results.Ok(rutinas);
        }
        catch (Exception)
        {
            return Results.Problem(
                title:
                    "Error al consultar rutinas del cliente",
                detail:
                    "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Entrenador");
});

// ===============================
// MI RUTINA - OBTENER CLIENTE
// #925 + #926
// ===============================

// ===============================
// MI RUTINA - OBTENER CLIENTE
// Y DEVOLVER DÍAS ORDENADOS
// #925 + #926 + #927
// ===============================

app.MapGet(
    "/api/rutinas/mi-rutina",
    async (
        ClaimsPrincipal usuario,
        IConfiguration configuration
    ) =>
    {
        var sub =
            usuario.FindFirst("sub")?.Value;

        if (string.IsNullOrWhiteSpace(sub) ||
            !int.TryParse(sub, out var idUsuario))
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

        try
        {
            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            // ===============================
            // OBTENER CLIENTE DESDE EL JWT
            // ===============================

            await using var clienteCommand =
                new NpgsqlCommand(
                    """
                    SELECT
                        id_cliente,
                        nombre_completo
                    FROM clientes
                    WHERE id_usuario = @id_usuario
                    LIMIT 1;
                    """,
                    connection
                );

            clienteCommand.Parameters.AddWithValue(
                "id_usuario",
                idUsuario
            );

            int idCliente;
            string nombreCliente;

            await using (var clienteReader =
                await clienteCommand.ExecuteReaderAsync())
            {
                if (!await clienteReader.ReadAsync())
                {
                    return Results.NotFound(new
                    {
                        mensaje =
                            "No se encontró un cliente asociado al usuario."
                    });
                }

                idCliente =
                    clienteReader.GetInt32(0);

                nombreCliente =
                    clienteReader.GetString(1);
            }

            // ===============================
            // OBTENER RUTINA DEL CLIENTE
            // ===============================

            await using var rutinaCommand =
                new NpgsqlCommand(
                    """
                    SELECT
                        id_rutina,
                        nombre,
                        descripcion
                    FROM rutinas
                    WHERE id_cliente = @id_cliente
                    ORDER BY id_rutina DESC
                    LIMIT 1;
                    """,
                    connection
                );

            rutinaCommand.Parameters.AddWithValue(
                "id_cliente",
                idCliente
            );

            int idRutina;
            string nombreRutina;
            string? descripcionRutina;

            await using (var rutinaReader =
                await rutinaCommand.ExecuteReaderAsync())
            {
                if (!await rutinaReader.ReadAsync())
                {
                    return Results.NotFound(new
                    {
                        mensaje =
                            "El cliente todavía no tiene una rutina asignada."
                    });
                }

                idRutina =
                    rutinaReader.GetInt32(0);

                nombreRutina =
                    rutinaReader.GetString(1);

                descripcionRutina =
                    rutinaReader.IsDBNull(2)
                        ? null
                        : rutinaReader.GetString(2);
            }

            // ===============================
            // OBTENER DÍAS ORDENADOS
            // #927
            // ===============================

            await using var diasCommand =
                new NpgsqlCommand(
                    """
                    SELECT
                        id_dia,
                        dia
                    FROM dias_rutina
                    WHERE id_rutina = @id_rutina
                    ORDER BY
                        CASE LOWER(dia)
                            WHEN 'lunes' THEN 1
                            WHEN 'martes' THEN 2
                            WHEN 'miércoles' THEN 3
                            WHEN 'miercoles' THEN 3
                            WHEN 'jueves' THEN 4
                            WHEN 'viernes' THEN 5
                            WHEN 'sábado' THEN 6
                            WHEN 'sabado' THEN 6
                            WHEN 'domingo' THEN 7
                            ELSE 8
                        END,
                        id_dia;
                    """,
                    connection
                );

            diasCommand.Parameters.AddWithValue(
                "id_rutina",
                idRutina
            );

            var diasBase =
                new List<(int IdDia, string Dia)>();

            await using (var diasReader =
                await diasCommand.ExecuteReaderAsync())
            {
                while (await diasReader.ReadAsync())
                {
                    diasBase.Add(
                        (
                            diasReader.GetInt32(0),
                            diasReader.GetString(1)
                        )
                    );
                }
            }

            // ===============================
            // OBTENER EJERCICIOS ORDENADOS
            // #928
            // ===============================

            var dias =
                new List<object>();

            foreach (var diaBase in diasBase)
            {
                await using var ejerciciosCommand =
                    new NpgsqlCommand(
                        """
                        SELECT
                            er.id_ejercicio_rutina,
                            er.id_ejercicio,
                            e.nombre,
                            e.descripcion,
                            er.series,
                            er.repeticiones,
                            er.orden,
                            e.imagen_url
                        FROM ejercicios_rutina er
                        INNER JOIN ejercicios e
                            ON e.id_ejercicio = er.id_ejercicio
                        WHERE er.id_dia = @id_dia
                        ORDER BY
                            er.orden,
                            er.id_ejercicio_rutina;
                        """,
                        connection
                    );

                ejerciciosCommand.Parameters.AddWithValue(
                    "id_dia",
                    diaBase.IdDia
                );

                var ejercicios =
                    new List<object>();

                await using var ejerciciosReader =
                    await ejerciciosCommand.ExecuteReaderAsync();

                while (await ejerciciosReader.ReadAsync())
                {
                    ejercicios.Add(new
                    {
                        idEjercicioRutina =
                            ejerciciosReader.GetInt32(0),

                        idEjercicio =
                            ejerciciosReader.GetInt32(1),

                        nombre =
                            ejerciciosReader.GetString(2),

                        descripcion =
                            ejerciciosReader.IsDBNull(3)
                                ? null
                                : ejerciciosReader.GetString(3),

                        series =
                            ejerciciosReader.GetInt32(4),

                        repeticiones =
                            ejerciciosReader.GetInt32(5),

                        orden =
                            ejerciciosReader.GetInt32(6),

                        imagenUrl =
                            ejerciciosReader.IsDBNull(7)
                                ? null
                                : ejerciciosReader.GetString(7)
                    });
                }

                dias.Add(new
                {
                    idDia = diaBase.IdDia,
                    dia = diaBase.Dia,
                    ejercicios
                });
            }

            // ===============================
            // RESPUESTA
            // ===============================

            return Results.Ok(new
            {
                idUsuario,
                idCliente,
                nombreCliente,
                idRutina,
                nombre = nombreRutina,
                descripcion = descripcionRutina,
                dias
            });
        }
        catch (Exception)
        {
            return Results.Problem(
                title:
                    "Error al consultar Mi Rutina",
                detail:
                    "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Cliente");
});

// ===============================
// URL WEB DE RUTINAS
// #929 + #930
// ===============================

app.MapGet(
    "/api/rutinas/url",
    () =>
    {
        const string urlRutinas =
            "https://gymflow-web-lkvv.onrender.com/rutinas";

        return Results.Ok(new
        {
            url = urlRutinas
        });
    }
)
.RequireAuthorization();

// ===============================
// MIS CLIENTES - ENTRENADOR
// #1279
// ===============================

// ===============================
// MIS CLIENTES - ENTRENADOR
// #1279
// ===============================

app.MapGet(
    "/api/entrenador/mis-clientes",
    async (
        ClaimsPrincipal usuario,
        EntrenadorService entrenadorService,
        IConfiguration configuration
    ) =>
    {
        var idEntrenador =
            await entrenadorService.ObtenerIdPersonalAsync(
                usuario
            );

        if (idEntrenador is null)
        {
            return Results.NotFound(new
            {
                mensaje =
                    "No se encontró información del entrenador."
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

        try
        {
            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            await using var command =
                new NpgsqlCommand(
                    """
                    SELECT
                        c.id_cliente,
                        c.id_usuario,
                        c.nombre_completo,
                        u.correo,
                        c.telefono,
                        u.estatus
                    FROM clientes c
                    INNER JOIN usuarios u
                        ON u.id_usuario = c.id_usuario
                    WHERE c.id_entrenador = @id_entrenador
                    ORDER BY c.nombre_completo;
                    """,
                    connection
                );

            command.Parameters.AddWithValue(
                "id_entrenador",
                idEntrenador.Value
            );

            await using var reader =
                await command.ExecuteReaderAsync();

            var clientes =
                new List<object>();

            while (await reader.ReadAsync())
            {
                var estatusTexto =
                    reader.GetString(5);

                clientes.Add(new
                {
                    idCliente =
                        reader.GetInt32(0),

                    idUsuario =
                        reader.GetInt32(1),

                    nombre =
                        reader.GetString(2),

                    correo =
                        reader.GetString(3),

                    telefono =
                        reader.GetString(4),

                    estatus =
                        string.Equals(
                            estatusTexto,
                            "Activo",
                            StringComparison.OrdinalIgnoreCase
                        )
                });
            }

            return Results.Ok(new
            {
                idEntrenador = idEntrenador.Value,
                clientes
            });
        }
        catch (Exception)
        {
            return Results.Problem(
                title:
                    "Error al consultar clientes del entrenador",
                detail:
                    "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization(policy =>
{
    policy.RequireRole("Entrenador");
});

// ===============================
// VERSION DEL SISTEMA
// ===============================

app.MapGet(
    "/api/sistema/version",
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

        try
        {
            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            await using var command =
                new NpgsqlCommand(
                    """
                    SELECT version
                    FROM system_versions
                    ORDER BY id DESC
                    LIMIT 1;
                    """,
                    connection
                );

            var resultado =
                await command.ExecuteScalarAsync();

            if (resultado is null ||
                resultado == DBNull.Value)
            {
                return Results.NotFound(new
                {
                    mensaje =
                        "No se encontró una versión del sistema."
                });
            }

            return Results.Ok(new
            {
                version =
                    Convert.ToString(resultado)
            });
        }
       catch (PostgresException ex)
        {
            app.Logger.LogError(
                ex,
                "Error PostgreSQL al consultar versión del sistema."
            );

            return Results.BadRequest(new
            {
                mensaje =
                    "No se pudo consultar la versión del sistema."
            });
        }
        catch (Exception)
        {
            return Results.Problem(
                title:
                    "Error al consultar versión",
                detail:
                    "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization();

app.Run();

