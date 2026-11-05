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
        'admin.instalacion@gymflow.test',
        public.crypt(:'admin_password', public.gen_salt('bf', 12)),
        'Activo',
        1
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

-- 7. Ajustar secuencias
SELECT setval('public.rol_id_rol_seq', 4, true);
SELECT setval('public.usuarios_id_usuario_seq', 1, true);
SELECT setval('public.personal_id_personal_seq', 1, true);
SELECT setval('public.membresias_id_membresia_seq', 3, true);

COMMIT;

\echo 'SEED de GymFlow completado correctamente.'