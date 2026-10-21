-- Solo para una base desechable con esquema y scripts Sprint 7 ya aplicados.
INSERT INTO roles(id_rol, nombre) VALUES (1,'Administrador'),(2,'Entrenador'),(3,'Recepcionista'),(4,'Cliente');
INSERT INTO usuarios(id_usuario,correo,contrasena_hash,id_rol) VALUES
 (1,'admin@example.com','hash-admin',1),
 (2,'empleado@example.com','hash-empleado',2),
 (3,'cliente@example.com','hash-cliente',4);
INSERT INTO personal(id_personal,id_usuario,nombre_completo,telefono,salario,dia_pago_salario,horario,fecha_alta)
VALUES (1,2,'Empleado original','4420000000',12345.67,15,'Vespertino','2026-01-01');
INSERT INTO personal_salarios_historial(id_personal,monto,periodicidad,vigente_desde,registrado_por)
VALUES (1,12345.67,'Mensual','2026-01-01',1);
INSERT INTO personal_nomina_pagos(id_personal,id_salario,periodo_inicio,periodo_fin,monto,fecha_pago,metodo,registrado_por)
SELECT 1,id_salario,'2026-09-01','2026-09-30',12345.67,'2026-09-30','Transferencia',1
FROM personal_salarios_historial WHERE id_personal=1;
INSERT INTO membresias(id_membresia,nombre_plan,costo_mensual,costo_anualidad) VALUES (1,'Plan prueba',100,1000);
INSERT INTO clientes(id_usuario,id_asistencia,nombre_completo,telefono,costo_mensual_acordado,costo_anual_acordado,id_membresia,id_entrenador)
VALUES (3,'PRUEBA001','Cliente prueba','4420000001',100,1000,1,1);
