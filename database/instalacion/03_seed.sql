-- GYMFLOW - 03_SEED.SQL
-- Ejecutar después de 02_ddl.sql con psql.
-- Solo para una instalación nueva.

\set ON_ERROR_STOP on
\if :{?admin_password}
\else
\prompt 'Contraseña temporal del administrador: ' admin_password
\endif

BEGIN;

-- 1. Roles oficiales
INSERT INTO public.roles (id_rol, nombre)
VALUES
    (1, 'Administrador'),
    (2, 'Recepcionista'),
    (3, 'Entrenador'),
    (4, 'Cliente');

-- 2. Crear administrador inicial
INSERT INTO public.usuarios
    (id_usuario, correo, contrasena_hash, estatus, id_rol)
VALUES
    (
        1,
        'admin@gymflow.com',
        public.crypt(:'admin_password', public.gen_salt('bf', 12)),
        'Activo',
        1
    );

-- 2.1 Crear cuentas adicionales de demostración
INSERT INTO public.usuarios
    (id_usuario, correo, contrasena_hash, estatus, id_rol)
VALUES
    (
        2,
        'recepcion@gymflow.com',
        public.crypt(:'admin_password', public.gen_salt('bf', 12)),
        'Activo',
        2
    ),
    (
        3,
        'entrenador@gymflow.com',
        public.crypt(:'admin_password', public.gen_salt('bf', 12)),
        'Activo',
        3
    ),
    (
        4,
        'cliente@gymflow.com',
        public.crypt(:'admin_password', public.gen_salt('bf', 12)),
        'Activo',
        4
    );

-- 3. Establecer contexto de auditoría
SELECT set_config('gymflow.usuario_actual', '1', true);

-- 4. Crear expediente administrativo
INSERT INTO public.personal
    (
        id_personal,
        id_usuario,
        nombre_completo,
        telefono,
        salario,
        dia_pago_salario,
        horario,
        fecha_alta
    )
VALUES
    (
        1,
        1,
        'Administrador Inicial',
        '0000000000',
        0,
        15,
        'Horario administrativo',
        CURRENT_DATE
    );

-- 4.1 Expedientes de recepción y entrenador
INSERT INTO public.personal
    (
        id_personal,
        id_usuario,
        nombre_completo,
        telefono,
        salario,
        dia_pago_salario,
        horario,
        fecha_alta
    )
VALUES
    (
        2,
        2,
        'Recepcionista Demo',
        '0000000001',
        0,
        15,
        'Horario de prueba',
        CURRENT_DATE
    ),
    (
        3,
        3,
        'Entrenador Demo',
        '0000000002',
        0,
        15,
        'Horario de prueba',
        CURRENT_DATE
    );

-- 5. Registrar salario inicial
INSERT INTO public.personal_salarios_historial
    (
        id_personal,
        monto,
        periodicidad,
        vigente_desde,
        motivo,
        registrado_por
    )
VALUES
    (
        1,
        0,
        'Mensual',
        CURRENT_DATE,
        'Instalación inicial',
        1
    );

-- 6. Membresías oficiales
INSERT INTO public.membresias
    (
        id_membresia,
        nombre_plan,
        costo_mensual,
        costo_anualidad,
        descripcion,
        activo
    )
VALUES
    (1, 'BasicFlow', 250, 500, '', TRUE),
    (3, 'PremiumFlow', 500, 5000,
     'Acceso completo al gimnasio, clases especiales y área premium', TRUE);

-- 6.1 Cliente inicial sin entrenador
INSERT INTO public.clientes
    (
        id_cliente,
        id_usuario,
        id_asistencia,
        nombre_completo,
        telefono,
        costo_mensual_acordado,
        costo_anual_acordado,
        id_membresia,
        id_entrenador
    )
VALUES
    (
        1,
        4,
        'GF000001',
        'Cliente Demo',
        '0000000003',
        250,
        500,
        1,
        NULL
    );

-- 7. Ajustar secuencias
SELECT setval('public.rol_id_rol_seq', 4, true);
SELECT setval('public.usuarios_id_usuario_seq', 4, true);
SELECT setval('public.personal_id_personal_seq', 3, true);
SELECT setval('public.membresias_id_membresia_seq', 3, true);

SELECT setval('public.clientes_id_cliente_seq', 1, true);

COMMIT;

\echo 'SEED de GymFlow completado correctamente.'