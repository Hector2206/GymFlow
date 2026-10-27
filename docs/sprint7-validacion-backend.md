# Sprint 7 — Backend y base de datos

## Alcance implementado

- Indicadores: total de clientes, membresías activas,
  asistencias aprobadas del día y pagos registrados.
- Ingresos por periodo con fechas inclusivas.
- Búsqueda de clientes por nombre y correo.
- Filtros combinables por estatus, vigencia y membresía.
- Verificación de administrador activo en estos endpoints.
- Scripts SQL 007–014.

## Comprobaciones manuales realizadas

API ejecutada localmente contra la base utilizada durante
las comprobaciones. Esto no acredita despliegue del backend.

Resultados observados:
- Total de clientes: 14.
- Membresías activas: 8.
- Asistencias del día: 0.
- Pagos registrados: 21.
- Ingresos del 2026-09-13 al 2026-09-22: 15000.00,
  coincidentes con SQL.
- Ingresos de octubre de 2026: 0.

También se comprobaron:
- Fechas faltantes, inválidas e invertidas: 400.
- Sin autenticación: 401.
- Roles distintos de Administrador: 403.
- Búsquedas por nombre y correo.
- Coincidencias sin distinguir mayúsculas.
- Filtros combinados y lista vacía sin coincidencias.
- Parámetros de filtros inválidos: 400.
- Búsquedas de % y _: respuesta 200; falta documentar
  la comprobación del contenido literal de la respuesta.

## Pendientes antes del cierre operativo

- Confirmar versión SQL 1.0.5 en cada entorno.
- Verificar migraciones y permisos del usuario de la API.
- Confirmar despliegue y funcionamiento en Render.
- Integrar los endpoints con el cliente web.
- Unificar la zona horaria de referencia entre servicios.
- Probar límites de vigencia y fechas en una base desechable.
- Probar administrador inactivo con JWT todavía vigente.
- Asistencias: falta comprobar un caso con registros aprobados
  y rechazados; el caso observado devolvió cero.

## Fuera del alcance de estas comprobaciones

Las pruebas funcionales pendientes de registro y cancelación
de nómina se conservan como pendientes independientes.
Sprint 8 aún no está implementado.