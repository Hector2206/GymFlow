using System.Text.Json;
using GymManagement.api.Models;
using GymManagement.api.Services;
using Microsoft.Extensions.Configuration;
using Npgsql;

static EditarPersonalRequest Valid() => new()
{
    NombreCompleto = " Ana López ", Correo = " ANA@example.com ",
    Telefono = " 4421234567 ", Horario = " Matutino "
};
static void Check(bool ok, string message)
{
    if (!ok) throw new Exception(message);
}
static async Task Reject<T>(Func<Task> action) where T : Exception
{
    try { await action(); }
    catch (T) { return; }
    throw new Exception($"Se esperaba {typeof(T).Name}");
}

var request = Valid();
request.NormalizarYValidar();
Check(request.NombreCompleto == "Ana López" && request.Correo == "ana@example.com"
    && request.Telefono == "4421234567" && request.Horario == "Matutino", "Normalización");
foreach (var invalid in new Action<EditarPersonalRequest>[] {
    x => x.NombreCompleto = null!, x => x.Correo = "incorrecto",
    x => x.Telefono = " ", x => x.Horario = new string('x', 101),
    x => x.NombreCompleto = new string('x', 151),
    x => x.Correo = new string('x', 140) + "@example.com",
    x => x.Telefono = new string('x', 21) })
{
    var bad = Valid(); invalid(bad);
    await Reject<ArgumentException>(() => { bad.NormalizarYValidar(); return Task.CompletedTask; });
}
foreach (var field in new[] { "salario", "sueldo", "puesto", "password", "fechaContratacion" })
    await Reject<JsonException>(() => {
        JsonSerializer.Deserialize<EditarPersonalRequest>("{\"" + field + "\":123}");
        return Task.CompletedTask;
    });
Console.WriteLine("PASS: normalización, límites, nulos y rechazo de campos protegidos.");

// Exclusivamente una base desechable, nunca una conexión de producción.
var cs = Environment.GetEnvironmentVariable("GYMFLOW_CHECKS_CONNECTION");
if (string.IsNullOrWhiteSpace(cs))
{
    Console.WriteLine("SKIP: integración; configurar GYMFLOW_CHECKS_CONNECTION en una base desechable.");
    return;
}
await using var db = new NpgsqlConnection(cs);
await db.OpenAsync();
async Task Exec(string sql) { await using var cmd = new NpgsqlCommand(sql, db); await cmd.ExecuteNonQueryAsync(); }
async Task<string> Snapshot() {
    await using var cmd = new NpgsqlCommand("""
        SELECT jsonb_build_array(
          (SELECT jsonb_agg(to_jsonb(p) - ARRAY['nombre_completo','telefono','horario','fecha_actualizacion'] ORDER BY id_personal) FROM personal p),
          (SELECT jsonb_agg(to_jsonb(u) - 'correo' ORDER BY id_usuario) FROM usuarios u),
          (SELECT jsonb_agg(to_jsonb(h) ORDER BY id_salario) FROM personal_salarios_historial h),
          (SELECT jsonb_agg(to_jsonb(n) ORDER BY id_pago) FROM personal_nomina_pagos n),
          (SELECT jsonb_agg(to_jsonb(c) ORDER BY id_cliente) FROM clientes c))::text;
        """, db);
    return (string)(await cmd.ExecuteScalarAsync())!;
}
var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string,string?> {
    ["ConnectionStrings:PostgreSQL"] = cs }).Build();
var service = new PersonalService(config);
var before = await Snapshot();
await service.EditarPersonal(1, Valid(), 1);
Check(before == await Snapshot(), "Se alteraron campos protegidos o historial");
await using (var cmd = new NpgsqlCommand("SELECT correo FROM usuarios WHERE id_usuario = 2", db))
    Check((string)(await cmd.ExecuteScalarAsync())! == "ana@example.com", "Correo sin actualizar");
await Reject<KeyNotFoundException>(() => service.EditarPersonal(999999, Valid(), 1));
await Reject<UnauthorizedAccessException>(() => service.EditarPersonal(1, Valid(), 2));
await Reject<ArgumentException>(() => service.EditarPersonal(0, Valid(), 1));
await Exec("UPDATE usuarios SET estatus = 'Inactivo' WHERE id_usuario = 2");
await Reject<InvalidOperationException>(() => service.EditarPersonal(1, Valid(), 1));
await Exec("UPDATE usuarios SET estatus = 'Activo' WHERE id_usuario = 2");
var duplicate = Valid(); duplicate.Correo = "admin@example.com";
await Reject<PostgresException>(() => service.EditarPersonal(1, duplicate, 1));
Check(before == await Snapshot(), "Cambios protegidos tras errores");
// Fallo después de actualizar usuarios: se debe revertir también el correo.
await Exec("""
    CREATE FUNCTION checks_fallo() RETURNS trigger LANGUAGE plpgsql AS $$
    BEGIN RAISE EXCEPTION 'Fallo simulado'; END $$;
    CREATE TRIGGER checks_fallo BEFORE UPDATE ON personal
    FOR EACH ROW EXECUTE FUNCTION checks_fallo();
    """);
try
{
    var failure = Valid(); failure.Correo = "revertir@example.com";
    await Reject<PostgresException>(() => service.EditarPersonal(1, failure, 1));
    await using var cmd = new NpgsqlCommand("SELECT correo FROM usuarios WHERE id_usuario = 2", db);
    Check((string)(await cmd.ExecuteScalarAsync())! == "ana@example.com", "No se revirtió el correo");
}
finally { await Exec("DROP TRIGGER checks_fallo ON personal; DROP FUNCTION checks_fallo()"); }
await using (var cmd = new NpgsqlCommand("SELECT count(*) FROM bitacora_auditoria WHERE id_usuario_app = 1 AND tabla_afectada IN ('usuarios','personal')", db))
    Check((long)(await cmd.ExecuteScalarAsync())! >= 2, "Falta auditoría del administrador");
Console.WriteLine("PASS: edición, invariantes, inexistente, permisos, baja, duplicados, rollback y auditoría.");

// API real en un proceso local con JWT y conexión exclusivamente de pruebas.
const string key = "gymflow-checks-only-key-at-least-32-characters";
var start = new System.Diagnostics.ProcessStartInfo("dotnet") {
    UseShellExecute = false, CreateNoWindow = true
};
start.ArgumentList.Add(typeof(PersonalService).Assembly.Location);
start.ArgumentList.Add("--urls"); start.ArgumentList.Add("http://127.0.0.1:55438");
start.Environment["Jwt__Key"] = key;
start.Environment["Jwt__Issuer"] = "checks";
start.Environment["Jwt__Audience"] = "checks";
start.Environment["ConnectionStrings__PostgreSQL"] = cs;
using var process = System.Diagnostics.Process.Start(start)!;
try
{
    using var http = new HttpClient { BaseAddress = new Uri("http://127.0.0.1:55438") };
    for (var attempt = 0; ; attempt++)
    {
        try { if ((await http.GetAsync("/health")).IsSuccessStatusCode) break; }
        catch (HttpRequestException) when (attempt < 50) { }
        if (attempt >= 50) throw new Exception("API no inició");
        await Task.Delay(100);
    }
    string Token(string role, string sub = "1") {
        string B64(byte[] bytes) => Convert.ToBase64String(bytes).TrimEnd('=').Replace('+','-').Replace('/','_');
        var header = B64(System.Text.Encoding.UTF8.GetBytes("{\"alg\":\"HS256\",\"typ\":\"JWT\"}"));
        var payload = B64(JsonSerializer.SerializeToUtf8Bytes(new {
            sub, role, iss = "checks", aud = "checks", exp = DateTimeOffset.UtcNow.AddMinutes(5).ToUnixTimeSeconds() }));
        var data = header + "." + payload;
        return data + "." + B64(System.Security.Cryptography.HMACSHA256.HashData(
            System.Text.Encoding.UTF8.GetBytes(key), System.Text.Encoding.UTF8.GetBytes(data)));
    }
    async Task Status(int expected, string body, string? token, int id = 1) {
        using var message = new HttpRequestMessage(HttpMethod.Put, $"/api/admin/personal/{id}");
        if (token != null) message.Headers.Authorization = new("Bearer", token);
        message.Content = new StringContent(body, System.Text.Encoding.UTF8, "application/json");
        using var response = await http.SendAsync(message);
        Check((int)response.StatusCode == expected,
            $"HTTP esperado {expected}, obtenido {(int)response.StatusCode}: {await response.Content.ReadAsStringAsync()}");
    }
    var json = JsonSerializer.Serialize(Valid());
    await Status(401, json, null);
    await Status(403, json, Token("Entrenador"));
    await Status(401, json, Token("Administrador", "abc"));
    await Status(403, json, Token("Administrador", "2"));
    await Status(400, "{\"salario\":100}", Token("Administrador"));
    await Status(400, "{}", Token("Administrador"));
    await Status(400, json, Token("Administrador"), 0);
    await Status(404, json, Token("Administrador"), 999999);
    var conflict = Valid(); conflict.Correo = "admin@example.com";
    await Status(409, JsonSerializer.Serialize(conflict), Token("Administrador"));
    await Exec("UPDATE personal SET fecha_baja = CURRENT_DATE WHERE id_personal = 1");
    await Status(409, json, Token("Administrador"));
    await Exec("UPDATE personal SET fecha_baja = NULL WHERE id_personal = 1");
    await Status(200, json, Token("Administrador"));
    Check(before == await Snapshot(), "Invariantes tras HTTP");
    Console.WriteLine("PASS: HTTP 200/400/401/403/404/409 y conservación tras endpoint real.");
}
finally
{
    if (!process.HasExited) process.Kill(entireProcessTree: true);
    await process.WaitForExitAsync();
}
