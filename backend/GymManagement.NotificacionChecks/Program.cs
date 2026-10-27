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

var configuration = new ConfigurationBuilder()
    .AddInMemoryCollection(new Dictionary<string, string?>
    {
        ["ConnectionStrings:PostgreSQL"] = connectionString
    })
    .Build();

var service = new NotificacionService(configuration);

static void Check(bool condicion, string mensaje)
{
    if (!condicion)
        throw new Exception(mensaje);
}

var propias = await service.ObtenerNotificaciones(3);
var notificacion = propias.Single(n => n.IdNotificacion == 1);

var ajenas = await service.ObtenerNotificaciones(1);

Check(
    ajenas.All(n => n.IdNotificacion != 1),
    "El listado expuso una notificación de otro usuario.");

var rechazada = false;

try
{
    await service.MarcarComoLeida(1, 1);
}
catch (KeyNotFoundException)
{
    rechazada = true;
}

Check(rechazada, "Otro usuario pudo marcar la notificación.");

var trasRechazo = (await service.ObtenerNotificaciones(3))
    .Single(n => n.IdNotificacion == 1);

Check(
    trasRechazo.Leida == notificacion.Leida &&
    trasRechazo.FechaLectura == notificacion.FechaLectura,
    "El intento ajeno modificó la notificación.");

Console.WriteLine("PASS: aislamiento entre usuarios.");

var contadorAntes = await service.ObtenerNoLeidas(3);

await service.MarcarComoLeida(1, 3);

var primeraLectura = (await service.ObtenerNotificaciones(3))
    .Single(n => n.IdNotificacion == 1);

Check(
    primeraLectura.Leida &&
    primeraLectura.FechaLectura.HasValue,
    "No se registró correctamente la lectura.");

var contadorDespues = await service.ObtenerNoLeidas(3);
var esperado = contadorAntes - (notificacion.Leida ? 0 : 1);

Check(
    contadorDespues == esperado,
    "El contador de no leídas no corresponde.");

await Task.Delay(100);
await service.MarcarComoLeida(1, 3);

var segundaLectura = (await service.ObtenerNotificaciones(3))
    .Single(n => n.IdNotificacion == 1);

Check(
    segundaLectura.FechaLectura == primeraLectura.FechaLectura,
    "Repetir la lectura cambió su primera fecha.");

Check(
    await service.ObtenerNoLeidas(3) == contadorDespues,
    "Repetir la lectura alteró el contador.");

Console.WriteLine("PASS: lectura propia y contador.");
Console.WriteLine("PASS: primera fecha de lectura conservada.");