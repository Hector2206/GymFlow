create sequence rol_id_rol_seq
    as integer;

alter sequence rol_id_rol_seq owner to gymflow_app;

create table system_versions
(
    id         serial
        primary key,
    version    varchar(20) not null,
    updated_at timestamp default CURRENT_TIMESTAMP
);

alter table system_versions
    owner to gymflow_app;

create table roles
(
    id_rol integer default nextval('rol_id_rol_seq'::regclass) not null
        constraint rol_pkey
            primary key,
    nombre varchar(50)                                         not null
        constraint rol_nombre_key
            unique
);

alter table roles
    owner to gymflow_app;

alter sequence rol_id_rol_seq owned by roles.id_rol;

create table membresias
(
    id_membresia    serial
        primary key,
    nombre_plan     varchar(100)   not null
        unique,
    costo_mensual   numeric(10, 2) not null
        constraint membresias_costo_mensual_check
            check (costo_mensual >= (0)::numeric),
    costo_anualidad numeric(10, 2) not null
        constraint membresias_costo_anualidad_check
            check (costo_anualidad >= (0)::numeric)
);

alter table membresias
    owner to gymflow_app;

create table usuarios
(
    id_usuario      serial
        primary key,
    correo          varchar(150)                                    not null
        unique,
    contrasena_hash varchar(255)                                    not null,
    estatus         varchar(20) default 'Activo'::character varying not null
        constraint usuarios_estatus_check
            check ((estatus)::text = ANY
                   ((ARRAY ['Activo'::character varying, 'Inactivo'::character varying])::text[])),
    id_rol          integer                                         not null
        constraint fk_rol
            references roles
            on delete restrict,
    google_id       varchar(255)
        unique
);

alter table usuarios
    owner to gymflow_app;

create table personal
(
    id_personal      serial
        primary key,
    id_usuario       integer                   not null
        unique
        constraint fk_usuario_personal
            references usuarios
            on delete restrict,
    nombre_completo  varchar(150)              not null,
    telefono         varchar(20)               not null,
    salario          numeric(10, 2)            not null
        constraint personal_salario_check
            check (salario >= (0)::numeric),
    dia_pago_salario integer                   not null
        constraint personal_dia_pago_salario_check
            check ((dia_pago_salario >= 1) AND (dia_pago_salario <= 31)),
    horario          varchar(100)              not null,
    fecha_alta       date default CURRENT_DATE not null
);

alter table personal
    owner to gymflow_app;

create table clientes
(
    id_cliente             serial
        primary key,
    id_usuario             integer                   not null
        unique
        constraint fk_usuario_cliente
            references usuarios
            on delete restrict,
    id_asistencia          varchar(20)               not null
        unique,
    nombre_completo        varchar(150)              not null,
    telefono               varchar(20)               not null,
    foto_url               varchar(255),
    pdf_contrato           varchar(255),
    costo_mensual_acordado numeric(10, 2)            not null
        constraint clientes_costo_mensual_acordado_check
            check (costo_mensual_acordado >= (0)::numeric),
    costo_anual_acordado   numeric(10, 2)            not null
        constraint clientes_costo_anual_acordado_check
            check (costo_anual_acordado >= (0)::numeric),
    fecha_pago_mensual     date,
    fecha_pago_anualidad   date,
    fecha_alta             date default CURRENT_DATE not null,
    id_membresia           integer                   not null
        constraint fk_membresia_cliente
            references membresias
            on delete restrict,
    id_entrenador          integer
        constraint fk_entrenador_cliente
            references personal
            on delete set null
);

alter table clientes
    owner to gymflow_app;

create table historial_pagos
(
    id_pago           serial
        primary key,
    id_cliente        integer                             not null
        constraint fk_cliente_pago
            references clientes
            on delete restrict,
    id_recepcionista  integer                             not null
        constraint fk_recepcionista_pago
            references personal
            on delete restrict,
    monto_pagado      numeric(10, 2)                      not null
        constraint historial_pagos_monto_pagado_check
            check (monto_pagado > (0)::numeric),
    tipo_pago         varchar(20)                         not null
        constraint historial_pagos_tipo_pago_check
            check ((tipo_pago)::text = ANY
                   ((ARRAY ['Mensualidad'::character varying, 'Anualidad'::character varying])::text[])),
    fecha_transaccion timestamp default CURRENT_TIMESTAMP not null
);

alter table historial_pagos
    owner to gymflow_app;

create table asistencias
(
    id_asistencia_registro serial
        primary key,
    id_cliente             integer                             not null
        constraint fk_cliente_asistencia
            references clientes
            on delete restrict,
    fecha_hora             timestamp default CURRENT_TIMESTAMP not null
);

alter table asistencias
    owner to gymflow_app;

create table bitacora_auditoria
(
    id_bitacora      serial
        primary key,
    id_usuario_app   integer,
    tabla_afectada   varchar(50)                         not null,
    accion_realizada varchar(10)                         not null
        constraint bitacora_auditoria_accion_realizada_check
            check ((accion_realizada)::text = ANY
                   ((ARRAY ['INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying])::text[])),
    datos_viejos     jsonb,
    datos_nuevos     jsonb,
    fecha_auditoria  timestamp default CURRENT_TIMESTAMP not null
);

alter table bitacora_auditoria
    owner to gymflow_app;

create view vw_usuarios_login
            (id_usuario, correo, contrasena_hash, google_id, estatus, id_rol, nombre_rol, nombre_perfil) as
SELECT u.id_usuario,
       u.correo,
       u.contrasena_hash,
       u.google_id,
       u.estatus,
       u.id_rol,
       r.nombre                                                          AS nombre_rol,
       COALESCE(p.nombre_completo, c.nombre_completo)::character varying AS nombre_perfil
FROM usuarios u
         JOIN roles r ON u.id_rol = r.id_rol
         LEFT JOIN personal p ON u.id_usuario = p.id_usuario
         LEFT JOIN clientes c ON u.id_usuario = c.id_usuario;

alter table vw_usuarios_login
    owner to gymflow_app;

create view vw_membresias_lista(id_membresia, nombre_plan, costo_mensual, costo_anualidad) as
SELECT id_membresia,
       nombre_plan,
       costo_mensual,
       costo_anualidad
FROM membresias;

alter table vw_membresias_lista
    owner to gymflow_app;

create view vw_personal_lista
            (id_personal, id_usuario, nombre_completo, correo, telefono, nombre_rol, horario, salario, estatus) as
SELECT p.id_personal,
       u.id_usuario,
       p.nombre_completo,
       u.correo,
       p.telefono,
       r.nombre AS nombre_rol,
       p.horario,
       p.salario,
       u.estatus
FROM personal p
         JOIN usuarios u ON p.id_usuario = u.id_usuario
         JOIN roles r ON u.id_rol = r.id_rol;

alter table vw_personal_lista
    owner to gymflow_app;

create view vw_clientes_lista
            (id_cliente, id_usuario, id_asistencia, nombre_completo, correo, telefono, nombre_plan,
             costo_mensual_acordado, estatus, nombre_entrenador)
as
SELECT c.id_cliente,
       u.id_usuario,
       c.id_asistencia,
       c.nombre_completo,
       u.correo,
       c.telefono,
       m.nombre_plan,
       c.costo_mensual_acordado,
       u.estatus,
       p.nombre_completo AS nombre_entrenador
FROM clientes c
         JOIN usuarios u ON c.id_usuario = u.id_usuario
         JOIN membresias m ON c.id_membresia = m.id_membresia
         LEFT JOIN personal p ON c.id_entrenador = p.id_personal;

alter table vw_clientes_lista
    owner to gymflow_app;

create view vw_historial_pagos (id_pago, fecha_transaccion, nombre_cliente, cobrado_por, monto_pagado, tipo_pago) as
SELECT p.id_pago,
       p.fecha_transaccion,
       c.nombre_completo   AS nombre_cliente,
       rec.nombre_completo AS cobrado_por,
       p.monto_pagado,
       p.tipo_pago
FROM historial_pagos p
         JOIN clientes c ON p.id_cliente = c.id_cliente
         JOIN personal rec ON p.id_recepcionista = rec.id_personal;

alter table vw_historial_pagos
    owner to gymflow_app;

create view vw_asistencias_lista(id_asistencia_registro, clave_ingreso, nombre_cliente, fecha_hora) as
SELECT a.id_asistencia_registro,
       c.id_asistencia   AS clave_ingreso,
       c.nombre_completo AS nombre_cliente,
       a.fecha_hora
FROM asistencias a
         JOIN clientes c ON a.id_cliente = c.id_cliente;

alter table vw_asistencias_lista
    owner to gymflow_app;

create view vw_reporte_auditoria
            (id_bitacora, id_usuario_app, usuario_que_modifico, tabla_afectada, accion_realizada, fecha_auditoria,
             datos_viejos, datos_nuevos)
as
SELECT b.id_bitacora,
       b.id_usuario_app,
       u.correo                                               AS usuario_que_modifico,
       b.tabla_afectada,
       b.accion_realizada,
       to_char(b.fecha_auditoria, 'DD/MM/YYYY HH24:MI'::text) AS fecha_auditoria,
       b.datos_viejos,
       b.datos_nuevos
FROM bitacora_auditoria b
         LEFT JOIN usuarios u ON b.id_usuario_app = u.id_usuario
ORDER BY b.fecha_auditoria DESC;

alter table vw_reporte_auditoria
    owner to gymflow_app;

create procedure sp_alta_personal(IN p_correo character varying, IN p_contrasena_hash character varying, IN p_id_rol integer, IN p_nombre_completo character varying, IN p_telefono character varying, IN p_salario numeric, IN p_dia_pago integer, IN p_horario character varying)
    language plpgsql
as
$$
DECLARE
    v_id_usuario INTEGER; -- Aquí guardaremos el ID que se genera automáticamente
BEGIN
    -- 1. Creamos la cuenta de inicio de sesión
    -- Nota: google_id nace nulo. Si luego el empleado inicia con Google, el backend lo actualizará.
    INSERT INTO usuarios (correo, contrasena_hash, id_rol)
    VALUES (p_correo, p_contrasena_hash, p_id_rol)
    RETURNING id_usuario INTO v_id_usuario;

    -- 2. Creamos el perfil del empleado, usando el ID que acabamos de generar
    INSERT INTO personal (id_usuario, nombre_completo, telefono, salario, dia_pago_salario, horario)
    VALUES (v_id_usuario, p_nombre_completo, p_telefono, p_salario, p_dia_pago, p_horario);
END;
$$;

alter procedure sp_alta_personal(varchar, varchar, integer, varchar, varchar, numeric, integer, varchar) owner to gymflow_app;

create procedure sp_modificar_personal(IN p_id_personal integer, IN p_telefono character varying, IN p_salario numeric, IN p_dia_pago integer, IN p_horario character varying)
    language plpgsql
as
$$
BEGIN
    UPDATE personal
    SET telefono = p_telefono,
        salario = p_salario,
        dia_pago_salario = p_dia_pago,
        horario = p_horario
    WHERE id_personal = p_id_personal;
END;
$$;

alter procedure sp_modificar_personal(integer, varchar, numeric, integer, varchar) owner to gymflow_app;

create procedure sp_baja_personal(IN p_id_personal integer)
    language plpgsql
as
$$
BEGIN
    -- Apagamos la cuenta de inicio de sesión vinculada a este empleado
    UPDATE usuarios
    SET estatus = 'Inactivo'
    WHERE id_usuario = (SELECT id_usuario FROM personal WHERE id_personal = p_id_personal);
END;
$$;

alter procedure sp_baja_personal(integer) owner to gymflow_app;

create procedure sp_alta_cliente(IN p_correo character varying, IN p_contrasena_hash character varying, IN p_id_asistencia character varying, IN p_nombre_completo character varying, IN p_telefono character varying, IN p_id_membresia integer, IN p_costo_mensual numeric, IN p_costo_anual numeric)
    language plpgsql
as
$$
DECLARE
    v_id_usuario INTEGER;
BEGIN
    -- 1. Creamos la cuenta de acceso (El Rol 4 siempre será Cliente)
    -- El google_id nace nulo, la app lo llenará si el usuario decide usar Google después.
    INSERT INTO usuarios (correo, contrasena_hash, id_rol)
    VALUES (p_correo, p_contrasena_hash, 4)
    RETURNING id_usuario INTO v_id_usuario;

    -- 2. Creamos el expediente físico del cliente vinculándolo al usuario
    INSERT INTO clientes (id_usuario, id_asistencia, nombre_completo, telefono, id_membresia, costo_mensual_acordado, costo_anual_acordado)
    VALUES (v_id_usuario, p_id_asistencia, p_nombre_completo, p_telefono, p_id_membresia, p_costo_mensual, p_costo_anual);
END;
$$;

alter procedure sp_alta_cliente(varchar, varchar, varchar, varchar, varchar, integer, numeric, numeric) owner to gymflow_app;

create procedure sp_modificar_cliente(IN p_id_cliente integer, IN p_telefono character varying, IN p_id_membresia integer, IN p_costo_mensual numeric, IN p_costo_anual numeric, IN p_id_entrenador integer)
    language plpgsql
as
$$
BEGIN
    UPDATE clientes
    SET telefono = p_telefono,
        id_membresia = p_id_membresia,
        costo_mensual_acordado = p_costo_mensual,
        costo_anual_acordado = p_costo_anual,
        id_entrenador = p_id_entrenador
    WHERE id_cliente = p_id_cliente;
END;
$$;

alter procedure sp_modificar_cliente(integer, varchar, integer, numeric, numeric, integer) owner to gymflow_app;

create procedure sp_baja_cliente(IN p_id_cliente integer)
    language plpgsql
as
$$
BEGIN
    -- Buscamos al usuario vinculado a este cliente y le cortamos el acceso
    UPDATE usuarios
    SET estatus = 'Inactivo'
    WHERE id_usuario = (SELECT id_usuario FROM clientes WHERE id_cliente = p_id_cliente);
END;
$$;

alter procedure sp_baja_cliente(integer) owner to gymflow_app;

create procedure sp_registrar_pago(IN p_id_cliente integer, IN p_id_recepcionista integer, IN p_monto numeric, IN p_tipo character varying)
    language plpgsql
as
$$
BEGIN
    -- 1. Guardamos el registro intocable en el historial (la fecha se pone sola)
    INSERT INTO historial_pagos (id_cliente, id_recepcionista, monto_pagado, tipo_pago)
    VALUES (p_id_cliente, p_id_recepcionista, p_monto, p_tipo);

    -- 2. Actualizamos la fecha de pago en el perfil del cliente
    IF p_tipo = 'Mensualidad' THEN
        UPDATE clientes SET fecha_pago_mensual = CURRENT_DATE WHERE id_cliente = p_id_cliente;
    ELSIF p_tipo = 'Anualidad' THEN
        UPDATE clientes SET fecha_pago_anualidad = CURRENT_DATE WHERE id_cliente = p_id_cliente;
    END IF;
END;
$$;

alter procedure sp_registrar_pago(integer, integer, numeric, varchar) owner to gymflow_app;

create procedure sp_registrar_asistencia(IN p_clave_ingreso character varying)
    language plpgsql
as
$$
DECLARE
    v_id_cliente INTEGER;
    v_estatus VARCHAR;
BEGIN
    -- 1. Buscamos el ID interno del cliente y su estatus usando la clave digitada
    SELECT c.id_cliente, u.estatus
    INTO v_id_cliente, v_estatus
    FROM clientes c
    INNER JOIN usuarios u ON c.id_usuario = u.id_usuario
    WHERE c.id_asistencia = p_clave_ingreso;

    -- 2. Validaciones de seguridad (Esto le mandará un error a C# automáticamente)
    IF v_id_cliente IS NULL THEN
        RAISE EXCEPTION 'Clave incorrecta. No se encontró al cliente.';
    END IF;

    IF v_estatus = 'Inactivo' THEN
        RAISE EXCEPTION 'Acceso denegado. El cliente está dado de baja.';
    END IF;

    -- 3. Si todo está bien, registramos su entrada (la hora se pone sola)
    INSERT INTO asistencias (id_cliente) VALUES (v_id_cliente);
END;
$$;

alter procedure sp_registrar_asistencia(varchar) owner to gymflow_app;

create function fn_registrar_auditoria() returns trigger
    language plpgsql
as
$$
DECLARE
    v_id_usuario_app INTEGER;
BEGIN
    -- Intentamos leer quién fue el usuario desde la configuración que mande C#
    BEGIN
        v_id_usuario_app := current_setting('gymflow.usuario_actual')::INTEGER;
    EXCEPTION WHEN OTHERS THEN
        v_id_usuario_app := NULL; -- Si por algo falla, no bloqueamos el sistema
    END;

    -- Evaluamos qué pasó y lo guardamos
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO bitacora_auditoria (id_usuario_app, tabla_afectada, accion_realizada, datos_viejos)
        VALUES (v_id_usuario_app, TG_TABLE_NAME, TG_OP, row_to_json(OLD));
        RETURN OLD;

    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO bitacora_auditoria (id_usuario_app, tabla_afectada, accion_realizada, datos_viejos, datos_nuevos)
        VALUES (v_id_usuario_app, TG_TABLE_NAME, TG_OP, row_to_json(OLD), row_to_json(NEW));
        RETURN NEW;

    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO bitacora_auditoria (id_usuario_app, tabla_afectada, accion_realizada, datos_nuevos)
        VALUES (v_id_usuario_app, TG_TABLE_NAME, TG_OP, row_to_json(NEW));
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$;

alter function fn_registrar_auditoria() owner to gymflow_app;

create trigger trg_auditoria_usuarios
    after insert or update or delete
    on usuarios
    for each row
execute procedure fn_registrar_auditoria();

create trigger trg_auditoria_personal
    after insert or update or delete
    on personal
    for each row
execute procedure fn_registrar_auditoria();

create trigger trg_auditoria_clientes
    after insert or update or delete
    on clientes
    for each row
execute procedure fn_registrar_auditoria();

create trigger trg_auditoria_pagos
    after insert or update or delete
    on historial_pagos
    for each row
execute procedure fn_registrar_auditoria();

create procedure sp_modificar_cliente(IN p_id_usuario_app integer, IN p_id_cliente integer, IN p_telefono character varying, IN p_id_membresia integer, IN p_costo_mensual numeric, IN p_costo_anual numeric, IN p_id_entrenador integer)
    language plpgsql
as
$$
BEGIN
    -- 1. Le avisamos a la base de datos "Quién" está haciendo esto para el Trigger
    PERFORM set_config('gymflow.usuario_actual', p_id_usuario_app::TEXT, true);

    -- 2. Hacemos la actualización normal
    UPDATE clientes
    SET telefono = p_telefono,
        id_membresia = p_id_membresia,
        costo_mensual_acordado = p_costo_mensual,
        costo_anual_acordado = p_costo_anual,
        id_entrenador = p_id_entrenador
    WHERE id_cliente = p_id_cliente;
END;
$$;

alter procedure sp_modificar_cliente(integer, integer, varchar, integer, numeric, numeric, integer) owner to gymflow_app;

create procedure sp_vincular_google(IN p_correo character varying, IN p_google_id character varying)
    language plpgsql
as
$$
BEGIN
    UPDATE usuarios
    SET google_id = p_google_id
    WHERE correo = p_correo;
END;
$$;

alter procedure sp_vincular_google(varchar, varchar) owner to gymflow_app;

create function fn_generar_codigo_acceso() returns trigger
    language plpgsql
as
$$
BEGIN
    IF NEW.id_asistencia IS NULL OR NEW.id_asistencia = '' THEN
        NEW.id_asistencia :=
            'GF' || LPAD(NEW.id_cliente::TEXT, 6, '0');
    END IF;

    RETURN NEW;
END;
$$;

alter function fn_generar_codigo_acceso() owner to gymflow_app;

create trigger trg_generar_codigo_acceso
    before insert
    on clientes
    for each row
execute procedure fn_generar_codigo_acceso();

create procedure sp_alta_cliente(IN p_correo character varying, IN p_contrasena_hash character varying, IN p_nombre_completo character varying, IN p_telefono character varying, IN p_id_membresia integer, IN p_costo_mensual numeric, IN p_costo_anual numeric)
    language plpgsql
as
$$
DECLARE
    v_id_usuario INTEGER;
BEGIN
    INSERT INTO usuarios (
        correo,
        contrasena_hash,
        id_rol
    )
    VALUES (
        p_correo,
        p_contrasena_hash,
        4
    )
    RETURNING id_usuario INTO v_id_usuario;

    INSERT INTO clientes (
        id_usuario,
        nombre_completo,
        telefono,
        id_membresia,
        costo_mensual_acordado,
        costo_anual_acordado
    )
    VALUES (
        v_id_usuario,
        p_nombre_completo,
        p_telefono,
        p_id_membresia,
        p_costo_mensual,
        p_costo_anual
    );
END;
$$;

alter procedure sp_alta_cliente(varchar, varchar, varchar, varchar, integer, numeric, numeric) owner to gymflow_app;

