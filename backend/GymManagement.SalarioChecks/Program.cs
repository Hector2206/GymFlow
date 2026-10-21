using GymManagement.api.Models;
using GymManagement.api.Services;
using Microsoft.Extensions.Configuration;
using Npgsql;

Console.Write("Contraseña de PostgreSQL local: ");

var password = "";
while (true)
{
    var key = Console.ReadKey(intercept: true);

    if (key.Key == ConsoleKey.Enter)
        break;

    if (key.Key == ConsoleKey.Backspace)
    {
        if (password.Length > 0)
            password = password[..^1];
    }
    else if (!char.IsControl(key.KeyChar))
    {
        password += key.KeyChar;
    }
}
Console.WriteLine();

var connectionString = new NpgsqlConnectionStringBuilder
{
    Host = "localhost",
    Port = 5432,
    Database = "gymflow_rollback_prueba",
    Username = "postgres",
    Password = password,
    Pooling = false
}.ConnectionString;

await using var db = new NpgsqlConnection(connectionString);
await db.OpenAsync();

async Task Execute(string sql)
{
    await using var command = new NpgsqlCommand(sql, db);
    await command.ExecuteNonQueryAsync();
}

async Task<string> Snapshot()
{
    await using var command = new NpgsqlCommand("""
        SELECT jsonb_build_object(
            'personal',
                (SELECT jsonb_agg(to_jsonb(p) ORDER BY id_personal)
                 FROM personal p),
            'salarios',
                (SELECT jsonb_agg(to_jsonb(h) ORDER BY id_salario)
                 FROM personal_salarios_historial h),
            'nomina',
                (SELECT jsonb_agg(to_jsonb(n) ORDER BY id_pago)
                 FROM personal_nomina_pagos n),
            'auditoria',
                (SELECT jsonb_agg(fila ORDER BY fila::text)
                 FROM (
                     SELECT to_jsonb(b) AS fila
                     FROM bitacora_auditoria b
                 ) datos)
        )::text;
        """, db);

    return (string)(await command.ExecuteScalarAsync())!;
}

DateOnly fechaOperacion;

await using (var command = new NpgsqlCommand(
    "SELECT CURRENT_DATE;", db))
{
    await using var reader = await command.ExecuteReaderAsync();
    await reader.ReadAsync();
    fechaOperacion = reader.GetFieldValue<DateOnly>(0);
}

var configuration = new ConfigurationBuilder()
    .AddInMemoryCollection(new Dictionary<string, string?>
    {
        ["ConnectionStrings:PostgreSQL"] = connectionString
    })
    .Build();

var service = new PersonalService(configuration);
var antes = await Snapshot();

// El error ocurre al actualizar personal, después de cerrar
// el salario anterior e insertar el nuevo dentro de la transacción.
await Execute("""
    CREATE FUNCTION public.prueba_fallo_salario()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RAISE EXCEPTION 'Fallo deliberado de prueba salarial'
            USING ERRCODE = 'P0001';
    END;
    $$;

    CREATE TRIGGER prueba_fallo_salario
    BEFORE UPDATE OF salario ON public.personal
    FOR EACH ROW
    EXECUTE FUNCTION public.prueba_fallo_salario();
    """);

try
{
    var falloEsperado = false;

    try
    {
        await service.CambiarSalario(
            1,
            new CambiarSalarioRequest
            {
                Monto = 15000m,
                VigenteDesde = fechaOperacion,
                Motivo = "Prueba local de rollback"
            },
            1);
    }
    catch (PostgresException ex)
        when (ex.SqlState == "P0001" &&
              ex.MessageText == "Fallo deliberado de prueba salarial")
    {
        falloEsperado = true;
        Console.WriteLine("OK: se alcanzó el fallo intermedio.");
    }

    if (!falloEsperado)
        throw new Exception("No ocurrió el fallo esperado.");

    var despues = await Snapshot();

    if (antes != despues)
        throw new Exception(
            "ERROR: los datos cambiaron pese al fallo.");

    Console.WriteLine(
        "PASS: rollback correcto. Personal, historial salarial, " +
        "nómina y auditoría permanecen iguales.");
}
finally
{
    await Execute("""
        DROP TRIGGER prueba_fallo_salario ON public.personal;
        DROP FUNCTION public.prueba_fallo_salario();
        """);
}