using Npgsql;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();

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

app.Run();