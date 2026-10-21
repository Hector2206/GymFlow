# Verificaciones de edición de personal

Ejecutar desde la raíz del repositorio:

```powershell
dotnet run --project backend/GymManagement.Checks
```

Sin conexión se prueban normalización, límites y rechazo de campos ajenos.
Para integración crear una base PostgreSQL **desechable y vacía**, con un usuario
que pueda crear tablas, funciones y triggers. No utilizar la base de desarrollo
compartida ni producción: las pruebas cambian datos ficticios deliberadamente.

1. Crear el rol `gymflow_app` si aún no existe.
2. Cargar `database/Respaldo_Schema/gymflow_schema_actual.sql`.
3. Aplicar los scripts SQL `database/sprint7/001` a `005`, en orden.
4. Cargar `backend/GymManagement.Checks/seed.sql` una sola vez.
5. Definir `GYMFLOW_CHECKS_CONNECTION` con la conexión a esa base.
6. Ejecutar el comando anterior. El puerto local 55438 debe estar libre.

Se comprueban los campos protegidos de usuarios y personal y el contenido completo
de historial salarial, pagos de nómina y asignaciones de clientes antes y después.
Se prueba rollback con un trigger de fallo deliberado y auditoría del administrador.
También se inicia la API real con JWT ficticios para verificar HTTP
200/400/401/403/404/409, sin utilizar la configuración de acceso de producción.
El proceso de API se detiene al terminar. El runner no elimina la base.

Validado en .NET 10.0.302 y PostgreSQL 18. No se añadieron paquetes de pruebas.
La restauración reportó NU1903 en Microsoft.OpenApi 2.0.0, dependencia preexistente.
La prueba de concurrencia edición/baja no está automatizada; ambas operaciones
usan `FOR UPDATE OF p, u` dentro de una transacción.
