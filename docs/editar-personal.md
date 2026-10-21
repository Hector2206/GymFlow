# Edición de empleados — Sprint 7

Base: main `5b63f007906885c98928b45943bb0521533f43ef`.

`PUT /api/admin/personal/{id:int}`, JWT con rol Administrador y `sub` entero positivo.
También se comprueba en PostgreSQL que el administrador sigue activo.

```json
{
  "nombreCompleto": "Ana López",
  "correo": "ana@example.com",
  "telefono": "4421234567",
  "horario": "Lunes a viernes de 08:00 a 16:00"
}
```

Los cuatro campos son obligatorios. Se recortan espacios exteriores y el correo
se normaliza a minúsculas. Límites del esquema: 150, 150, 20 y 100 caracteres.
Se rechazan campos desconocidos, incluidos sueldo, salario, puesto y password.

Respuestas: 200 `{ mensaje, idPersonal }`; 400 datos inválidos; 401 sin identidad
válida; 403 sin permisos; 404 empleado inexistente o fuera de los dos puestos
permitidos; 409 empleado inactivo/con baja o correo duplicado; 500 error interno.

La transacción bloquea personal y su usuario con el mismo mecanismo que la baja.
Solo actualiza nombre, teléfono, horario, fecha_actualizacion y correo.
No usa sp_modificar_personal porque también actualiza salario y día de pago.
No cambia rol, contraseña, fechas de alta/baja, asignaciones, salario,
personal_salarios_historial ni personal_nomina_pagos. Los triggers existentes
añaden auditoría con gymflow.usuario_actual; no se reescribe el historial.
No requiere migración SQL; presupone los scripts 001–005 de Sprint 7 aplicados.

Commits previstos: contrato/DTO; servicio y endpoint; verificaciones.
