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
)
.RequireAuthorization();

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
                        estado
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
                        reader.GetBoolean(3)
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
                        estado
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
                    reader.GetBoolean(3)
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
        CrearEjercicioRequest request,
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
                        descripcion = @descripcion
                    WHERE id_ejercicio = @id_ejercicio;
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
                nombre = request.Nombre,
                descripcion = request.Descripcion,
                mensaje = "Ejercicio actualizado correctamente."
            });
        }
        catch (PostgresException ex)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "No se pudo actualizar el ejercicio.",
                detalle = ex.MessageText
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
.RequireAuthorization();

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
.RequireAuthorization();


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
                        estado
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
                        reader.GetBoolean(3)
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
// #913
// ===============================

app.MapPost(
    "/api/rutinas",
    async (
        CrearRutinaRequest request,
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
            await using var transaction =
                await connection.BeginTransactionAsync();
            await using var clienteCommand =
                new NpgsqlCommand(
                    """
                    SELECT COUNT(*)
                    FROM clientes
                    WHERE id_cliente = @id_cliente;
                    """,
                    connection,
                    transaction
                );

            clienteCommand.Parameters.AddWithValue(
                "id_cliente",
                request.IdCliente
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

            var diasGuardados = new List<object>();

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

                var ejerciciosGuardados = new List<object>();

                foreach (var ejercicio in dia.Ejercicios)
                {
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
                        idEjercicio = ejercicio.IdEjercicio,
                        series = ejercicio.Series,
                        repeticiones = ejercicio.Repeticiones,
                        orden = ejercicio.Orden
                    });
                }

                diasGuardados.Add(new
                {
                    idDia,
                    dia = dia.Dia,
                    ejercicios = ejerciciosGuardados
                });
            }

            await transaction.CommitAsync();

            return Results.Created(
                $"/api/rutinas/{idRutina}",
                new
                {
                    idRutina,
                    idCliente = request.IdCliente,
                    nombre = request.Nombre,
                    descripcion = request.Descripcion,
                    dias = diasGuardados
                }
            );
        }
        catch (PostgresException ex)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "No se pudo registrar la rutina.",
                detalle = ex.MessageText
            });
        }
        catch (Exception)
        {
            return Results.Problem(
                title: "Error al registrar rutina",
                detail: "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization();


// ===============================
// EDITAR RUTINA
// #921
// ===============================

app.MapPut(
    "/api/rutinas/{idRutina:int}",
    async (
        int idRutina,
        CrearRutinaRequest request,
        IConfiguration configuration
    ) =>
    {
        if (idRutina <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje = "El id de la rutina no es válido."
            });
        }

        if (string.IsNullOrWhiteSpace(request.Nombre))
        {
            return Results.BadRequest(new
            {
                mensaje = "El nombre de la rutina es obligatorio."
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

            // Validar que el cliente exista
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
                request.IdCliente
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
                    connection
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
                    mensaje = "La rutina no existe."
                });
            }

            return Results.Ok(new
            {
                idRutina,
                idCliente = request.IdCliente,
                nombre = request.Nombre,
                descripcion = request.Descripcion,
                mensaje =
                    "Rutina actualizada correctamente."
            });
        }
        catch (PostgresException ex)
        {
            return Results.BadRequest(new
            {
                mensaje =
                    "No se pudo actualizar la rutina.",
                detalle = ex.MessageText
            });
        }
        catch (Exception)
        {
            return Results.Problem(
                title: "Error al actualizar rutina",
                detail: "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization();


// ===============================
// LISTAR RUTINAS
// #922
// ===============================

app.MapGet(
    "/api/rutinas",
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
                        r.id_rutina,
                        r.nombre,
                        r.descripcion,
                        r.id_cliente,
                        c.nombre_completo
                    FROM rutinas r
                    INNER JOIN clientes c
                        ON c.id_cliente = r.id_cliente
                    ORDER BY r.id_rutina DESC;
                    """,
                    connection
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
.RequireAuthorization();


// ===============================
// OBTENER RUTINA POR ID
// #923
// ===============================

app.MapGet(
    "/api/rutinas/{idRutina:int}",
    async (
        int idRutina,
        IConfiguration configuration
    ) =>
    {
        if (idRutina <= 0)
        {
            return Results.BadRequest(new
            {
                mensaje = "El id de la rutina no es válido."
            });
        }

        var connectionString =
            configuration.GetConnectionString("PostgreSQL");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            return Results.Problem(
                title: "Configuración faltante",
                detail: "No existe la cadena de conexión PostgreSQL.",
                statusCode: 500
            );
        }

        try
        {
            await using var connection =
                new NpgsqlConnection(connectionString);

            await connection.OpenAsync();

            // Encabezado de la rutina
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
                        mensaje = "La rutina no existe."
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

            // Días y ejercicios
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
                        er.orden
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
                            detalleReader.GetInt32(8)
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
                title: "Error al consultar rutina",
                detail: "Ocurrió un error interno.",
                statusCode: 500
            );
        }
    }
)
.RequireAuthorization();

// ===============================
// OBTENER RUTINAS POR CLIENTE
// #924
// ===============================

app.MapGet(
    "/api/rutinas/cliente/{idCliente:int}",
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
.RequireAuthorization();

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
                            er.orden
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
                            ejerciciosReader.GetInt32(6)
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
.RequireAuthorization();

// ===============================
// URL WEB DE RUTINAS
// #929
// ===============================

app.MapGet(
    "/api/rutinas/url",
    () =>
    {
        return Results.Ok(new
        {
            mensaje = "Endpoint de URL de rutinas disponible."
        });
    }
)
.RequireAuthorization();


app.Run();
