# Notificaciones — Sprint 8

## Generación de avisos

Tipo inicial: MembresiaPorVencer.
Anticipación inicial: 7 días, configurable.

Generar avisos para clientes con usuario Activo cuya fecha
de vencimiento esté entre la fecha de operación y esa fecha
más los días de anticipación, ambos extremos incluidos.

Calcular el vencimiento con la misma regla del Sprint 7:
la fecha mayor entre pago mensual + un mes y
pago de anualidad + un año.

Evitar duplicados por:
id_usuario, tipo y fecha_vencimiento.

Las notificaciones son avisos internos para web y móvil.
No incluyen correo electrónico ni notificaciones push.

## Datos

- id_notificacion
- id_usuario
- tipo
- titulo
- mensaje
- fecha_vencimiento
- leida
- fecha_lectura
- creado_en

## Endpoints

GET /api/notificaciones
Lista las notificaciones del usuario autenticado.
Orden: creado_en DESC, id_notificacion DESC.
Sin resultados: 200 con [].

GET /api/notificaciones/no-leidas
Devuelve { "noLeidas": 0 } para el usuario autenticado.

PATCH /api/notificaciones/{id}/lectura
Marca como leída una notificación propia.
Repetir la petición no cambia la primera fecha de lectura.
No requiere cuerpo.

Sin autenticación: 401.
Usuario inactivo: 403.
ID inválido: 400.
Notificación inexistente o de otro usuario: 404.

## Ejecución periódica

El generador deberá ejecutarse periódicamente.
La implementación y su despliegue se comprobarán antes
de declarar el módulo operativo.

## Fechas

Inicialmente se utilizará la fecha de PostgreSQL,
igual que en los indicadores del Sprint 7.
La unificación de zona horaria entre servicios sigue pendiente.