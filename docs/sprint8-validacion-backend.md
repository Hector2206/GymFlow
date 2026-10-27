# Sprint 8 — Notificaciones: backend y base de datos

## Implementado

- Tabla de notificaciones relacionada con usuarios.
- Índices para listado y contador de no leídas.
- Restricción única por usuario, tipo y vencimiento.
- Consulta de membresías próximas a vencer.
- Generación de avisos con anticipación configurable.
- Worker: revisión al iniciar y después cada hora por defecto.
- GET /api/notificaciones.
- GET /api/notificaciones/no-leidas.
- PATCH /api/notificaciones/{id}/lectura.
- Script de versión SQL 1.0.6.

## Comprobaciones realizadas

API local contra Render:
- Listado sin avisos: 200 con [].
- Contador sin avisos: 200 con noLeidas = 0.
- Sin autenticación: 401.
- Lectura con ID inválido: 400.
- Lectura con ID inexistente: 404.
- Worker: primera ejecución completada con cero candidatos.

Base local desechable y servicio real del backend:
- Generación de un aviso para cliente ficticio.
- Segunda generación: cero avisos nuevos.
- El cliente seguía siendo candidato y se conservó un único aviso.
- Un usuario no puede listar ni marcar avisos de otro.
- Lectura propia y actualización del contador correctas.
- Repetir lectura conserva la primera fecha.
- Un aviso leído no se vuelve a generar para el mismo vencimiento.

En Render se confirmó la existencia de la tabla y las dos funciones.

## Configuración

- Notificaciones:GeneracionHabilitada: true por defecto.
- Notificaciones:DiasAnticipacion: 7 por defecto.
- Notificaciones:IntervaloMinutos: 60 por defecto.

El worker funciona mientras la API permanece ejecutándose.
Las migraciones deben aplicarse antes de desplegar el backend.

## Pendientes de cierre operativo

- Confirmar ejecución del script de versión y registro 1.0.6
  en cada entorno.
- Confirmar despliegue del backend en Render.
- Verificar periodicidad con el alojamiento real;
  no se ha comprobado una segunda ejecución programada.
- Integración de los endpoints con web y móvil.
- Pruebas HTTP con notificaciones existentes y distintos usuarios.
- Pruebas de usuario inactivo y límites de anticipación.
- Unificar zona horaria de referencia entre servicios.
- Resolver advertencia de vulnerabilidad de Microsoft.OpenApi.

Los avisos son internos; no incluyen correo ni notificaciones push.