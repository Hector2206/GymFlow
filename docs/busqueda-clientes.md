# Búsqueda de clientes — Sprint 7

GET /api/admin/clientes

Acceso: JWT de Administrador y comprobación de administrador activo
en PostgreSQL.

Filtros opcionales y combinables mediante AND:
- nombre: coincidencia parcial, sin distinguir mayúsculas.
- correo: coincidencia parcial, sin distinguir mayúsculas.
- estatus: Activo o Inactivo.
- vigencia: Vigente, Vencida o SinPagos.
- idMembresia: entero positivo.

Nombre y correo:
- Recortar espacios exteriores.
- Texto vacío equivale a omitir el filtro.
- Máximo 150 caracteres por campo.
- Los caracteres % y _ se buscan literalmente.

Vigencia:
- Tomar la fecha mayor entre pago mensual + un mes y
  pago de anualidad + un año.
- Vigente: vencimiento igual o posterior a CURRENT_DATE.
- Vencida: vencimiento anterior a CURRENT_DATE.
- SinPagos: ambas fechas de pago son NULL.
- El estatus del usuario se filtra de manera independiente.

Respuesta: lista ordenada por nombre completo e ID de cliente.
Campos: idCliente, nombreCompleto, correo, telefono,
idMembresia, nombrePlan, estatus, vigencia y fechaVencimiento.

Sin coincidencias: 200 con [].
Filtros inválidos: 400.
Sin autenticación: 401.
Sin permisos o administrador inactivo: 403.

No devolver contraseñas, hashes ni identificadores de Google.
No modificar clientes, pagos ni membresías.
