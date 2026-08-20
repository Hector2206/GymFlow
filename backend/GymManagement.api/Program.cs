using Npgsql;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.AddControllers();

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        var key = builder.Configuration["Jwt:Key"];

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,

            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],

            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(key!)
            )
        };
    });

builder.Services.AddAuthorization();

builder.Services.AddScoped<GymManagement.api.Services.TokenService>();
builder.Services.AddScoped<GymManagement.api.Services.UsuarioService>();

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

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();

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

app.MapGet("/ping", async (IConfiguration configuration) =>
{
    try
    {
        var connectionString =
            configuration.GetConnectionString("PostgreSQL");

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

app.MapGet("/version", async (IConfiguration configuration) =>
{
    try
    {
        var connectionString =
            configuration.GetConnectionString("PostgreSQL");

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

app.MapControllers();

app.Run();