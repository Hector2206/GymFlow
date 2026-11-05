--
-- PostgreSQL database dump
--

\restrict a6gkNsHR9UdwgDbsohsQQbEQAFo7JU9t8WV7GUcHAs8oD0wArpuTgL9uYDMFkMC

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: fn_admin_ingresos_periodo(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_admin_ingresos_periodo(p_desde date, p_hasta date) RETURNS numeric
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    IF p_desde IS NULL OR p_hasta IS NULL THEN
        RAISE EXCEPTION 'Las fechas del periodo son obligatorias.'
            USING ERRCODE = '22023';
    END IF;

    IF p_hasta < p_desde THEN
        RAISE EXCEPTION 'La fecha final no puede ser anterior a la inicial.'
            USING ERRCODE = '22023';
    END IF;

    RETURN (
        SELECT COALESCE(SUM(h.monto_pagado), 0)
        FROM public.historial_pagos h
        WHERE h.fecha_transaccion >= p_desde::timestamp
          AND h.fecha_transaccion < (
              p_hasta::timestamp + INTERVAL '1 day'
          )
    );
END;
$$;


--
-- Name: fn_generar_avisos_vencimiento(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_generar_avisos_vencimiento(p_dias integer DEFAULT 7) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_insertadas BIGINT;
BEGIN
    INSERT INTO public.notificaciones (
        id_usuario,
        tipo,
        titulo,
        mensaje,
        fecha_vencimiento
    )
    SELECT
        c.id_usuario,
        'MembresiaPorVencer',
        'Tu membresÃ­a estÃ¡ prÃ³xima a vencer',
        FORMAT(
            'Tu membresÃ­a vence el %s. Consulta en recepciÃ³n para renovarla.',
            TO_CHAR(c.fecha_vencimiento, 'YYYY-MM-DD')
        ),
        c.fecha_vencimiento
    FROM public.fn_membresias_por_vencer(p_dias) c
    ON CONFLICT ON CONSTRAINT uq_notificacion_vencimiento
    DO NOTHING;

    GET DIAGNOSTICS v_insertadas = ROW_COUNT;

    RETURN v_insertadas;
END;
$$;


--
-- Name: fn_generar_codigo_acceso(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_generar_codigo_acceso() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.id_asistencia IS NULL OR NEW.id_asistencia = '' THEN
        NEW.id_asistencia :=
            'GF' || LPAD(NEW.id_cliente::TEXT, 6, '0');
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: fn_historial_precio_membresia(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_historial_precio_membresia() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_usuario integer;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF NEW.costo_mensual IS NOT DISTINCT FROM OLD.costo_mensual
           AND NEW.costo_anualidad IS NOT DISTINCT FROM OLD.costo_anualidad
        THEN
            RETURN NEW;
        END IF;
    END IF;

    v_usuario := NULLIF(
        current_setting('gymflow.usuario_actual', true),
        ''
    )::integer;

    IF v_usuario IS NULL THEN
        RAISE EXCEPTION
            'Se requiere el usuario administrador para registrar precios';
    END IF;

    PERFORM 1
    FROM public.usuarios u
    JOIN public.roles r ON r.id_rol = u.id_rol
    WHERE u.id_usuario = v_usuario
      AND u.estatus = 'Activo'
      AND r.nombre = 'Administrador'
    FOR SHARE OF u, r;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El usuario no es un administrador activo';
    END IF;

    INSERT INTO public.membresias_precios_historial (
        id_membresia,
        costo_mensual,
        costo_anualidad,
        id_usuario_app,
        origen
    )
    VALUES (
        NEW.id_membresia,
        NEW.costo_mensual,
        NEW.costo_anualidad,
        v_usuario,
        CASE
            WHEN TG_OP = 'INSERT' THEN 'Creacion'
            ELSE 'CambioPrecio'
        END
    );

    RETURN NEW;
END;
$$;


--
-- Name: fn_membresias_por_vencer(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_membresias_por_vencer(p_dias integer DEFAULT 7) RETURNS TABLE(id_cliente integer, id_usuario integer, nombre_completo character varying, fecha_vencimiento date)
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    IF p_dias IS NULL OR p_dias < 0 OR p_dias > 365 THEN
        RAISE EXCEPTION
            'Los dÃ­as de anticipaciÃ³n deben estar entre 0 y 365.'
            USING ERRCODE = '22023';
    END IF;

    RETURN QUERY
    WITH candidatos AS (
        SELECT
            c.id_cliente,
            c.id_usuario,
            c.nombre_completo,
            GREATEST(
                (c.fecha_pago_mensual + INTERVAL '1 month')::date,
                (c.fecha_pago_anualidad + INTERVAL '1 year')::date
            ) AS vencimiento
        FROM public.clientes c
        JOIN public.usuarios u
            ON u.id_usuario = c.id_usuario
        WHERE u.estatus = 'Activo'
    )
    SELECT
        c.id_cliente,
        c.id_usuario,
        c.nombre_completo,
        c.vencimiento
    FROM candidatos c
    WHERE c.vencimiento BETWEEN CURRENT_DATE
                           AND CURRENT_DATE + p_dias
    ORDER BY c.vencimiento, c.id_cliente;
END;
$$;


--
-- Name: fn_registrar_auditoria(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_registrar_auditoria() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_usuario INTEGER;
    v_anterior JSONB;
    v_nuevo JSONB;
BEGIN
    v_id_usuario := NULLIF(
        current_setting('gymflow.usuario_actual', true),
        ''
    )::INTEGER;

    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        v_anterior := to_jsonb(OLD);
    END IF;

    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        v_nuevo := to_jsonb(NEW);
    END IF;

    -- Nunca almacenar hashes ni identificadores Google
    IF TG_TABLE_NAME = 'usuarios' THEN
        v_anterior := v_anterior
            - 'contrasena_hash' - 'google_id';

        v_nuevo := v_nuevo
            - 'contrasena_hash' - 'google_id';
    END IF;

    INSERT INTO public.bitacora_auditoria (
        id_usuario_app,
        tabla_afectada,
        accion_realizada,
        datos_viejos,
        datos_nuevos
    )
    VALUES (
        v_id_usuario,
        TG_TABLE_NAME,
        TG_OP,
        v_anterior,
        v_nuevo
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: sp_alta_cliente(character varying, character varying, character varying, character varying, integer, numeric, numeric); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_alta_cliente(IN p_correo character varying, IN p_contrasena_hash character varying, IN p_nombre_completo character varying, IN p_telefono character varying, IN p_id_membresia integer, IN p_costo_mensual numeric, IN p_costo_anual numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    CALL public.sp_alta_cliente(
        p_correo,
        p_contrasena_hash,
        NULL::varchar,
        p_nombre_completo,
        p_telefono,
        p_id_membresia,
        p_costo_mensual,
        p_costo_anual
    );
END;
$$;


--
-- Name: sp_alta_cliente(character varying, character varying, character varying, character varying, character varying, integer, numeric, numeric); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_alta_cliente(IN p_correo character varying, IN p_contrasena_hash character varying, IN p_id_asistencia character varying, IN p_nombre_completo character varying, IN p_telefono character varying, IN p_id_membresia integer, IN p_costo_mensual numeric, IN p_costo_anual numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_usuario integer;
    v_mensual numeric(10,2);
    v_anual numeric(10,2);
    v_activo boolean;
BEGIN
    SELECT costo_mensual, costo_anualidad, activo
    INTO v_mensual, v_anual, v_activo
    FROM public.membresias
    WHERE id_membresia = p_id_membresia
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La membresÃ­a no existe';
    END IF;

    IF NOT v_activo THEN
        RAISE EXCEPTION 'La membresÃ­a estÃ¡ inactiva';
    END IF;

    INSERT INTO public.usuarios (
        correo, contrasena_hash, id_rol
    )
    VALUES (
        p_correo, p_contrasena_hash, 4
    )
    RETURNING id_usuario INTO v_id_usuario;

    INSERT INTO public.clientes (
        id_usuario,
        id_asistencia,
        nombre_completo,
        telefono,
        id_membresia,
        costo_mensual_acordado,
        costo_anual_acordado
    )
    VALUES (
        v_id_usuario,
        p_id_asistencia,
        p_nombre_completo,
        p_telefono,
        p_id_membresia,
        v_mensual,
        v_anual
    );
END;
$$;


--
-- Name: sp_alta_personal(character varying, character varying, integer, character varying, character varying, numeric, integer, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_alta_personal(IN p_correo character varying, IN p_contrasena_hash character varying, IN p_id_rol integer, IN p_nombre_completo character varying, IN p_telefono character varying, IN p_salario numeric, IN p_dia_pago integer, IN p_horario character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_usuario INTEGER; -- AquÃ­ guardaremos el ID que se genera automÃ¡ticamente
BEGIN
    -- 1. Creamos la cuenta de inicio de sesiÃ³n
    -- Nota: google_id nace nulo. Si luego el empleado inicia con Google, el backend lo actualizarÃ¡.
    INSERT INTO usuarios (correo, contrasena_hash, id_rol)
    VALUES (p_correo, p_contrasena_hash, p_id_rol)
    RETURNING id_usuario INTO v_id_usuario;

    -- 2. Creamos el perfil del empleado, usando el ID que acabamos de generar
    INSERT INTO personal (id_usuario, nombre_completo, telefono, salario, dia_pago_salario, horario)
    VALUES (v_id_usuario, p_nombre_completo, p_telefono, p_salario, p_dia_pago, p_horario);
END;
$$;


--
-- Name: sp_baja_cliente(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_baja_cliente(IN p_id_cliente integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Buscamos al usuario vinculado a este cliente y le cortamos el acceso
    UPDATE usuarios
    SET estatus = 'Inactivo'
    WHERE id_usuario = (SELECT id_usuario FROM clientes WHERE id_cliente = p_id_cliente);
END;
$$;


--
-- Name: sp_baja_personal(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_baja_personal(IN p_id_personal integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Apagamos la cuenta de inicio de sesiÃ³n vinculada a este empleado
    UPDATE usuarios
    SET estatus = 'Inactivo'
    WHERE id_usuario = (SELECT id_usuario FROM personal WHERE id_personal = p_id_personal);
END;
$$;


--
-- Name: sp_modificar_cliente(integer, character varying, integer, numeric, numeric, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_modificar_cliente(IN p_id_cliente integer, IN p_telefono character varying, IN p_id_membresia integer, IN p_costo_mensual numeric, IN p_costo_anual numeric, IN p_id_entrenador integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_cliente public.clientes%ROWTYPE;
    v_mensual numeric(10,2);
    v_anual numeric(10,2);
    v_activo boolean;
BEGIN
    SELECT *
    INTO v_cliente
    FROM public.clientes
    WHERE id_cliente = p_id_cliente
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El cliente no existe';
    END IF;

    IF p_id_membresia IS NULL THEN
        RAISE EXCEPTION 'La membresÃ­a es obligatoria';
    END IF;

    v_mensual := v_cliente.costo_mensual_acordado;
    v_anual := v_cliente.costo_anual_acordado;

    IF p_id_membresia <> v_cliente.id_membresia THEN
        SELECT costo_mensual, costo_anualidad, activo
        INTO v_mensual, v_anual, v_activo
        FROM public.membresias
        WHERE id_membresia = p_id_membresia
        FOR SHARE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'La membresÃ­a no existe';
        END IF;

        IF NOT v_activo THEN
            RAISE EXCEPTION 'La membresÃ­a estÃ¡ inactiva';
        END IF;
    END IF;

    UPDATE public.clientes
    SET telefono = p_telefono,
        id_membresia = p_id_membresia,
        costo_mensual_acordado = v_mensual,
        costo_anual_acordado = v_anual,
        id_entrenador = p_id_entrenador
    WHERE id_cliente = p_id_cliente;
END;
$$;


--
-- Name: sp_modificar_cliente(integer, integer, character varying, integer, numeric, numeric, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_modificar_cliente(IN p_id_usuario_app integer, IN p_id_cliente integer, IN p_telefono character varying, IN p_id_membresia integer, IN p_costo_mensual numeric, IN p_costo_anual numeric, IN p_id_entrenador integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM set_config(
        'gymflow.usuario_actual',
        p_id_usuario_app::text,
        true
    );

    CALL public.sp_modificar_cliente(
        p_id_cliente,
        p_telefono,
        p_id_membresia,
        p_costo_mensual,
        p_costo_anual,
        p_id_entrenador
    );
END;
$$;


--
-- Name: sp_modificar_personal(integer, character varying, numeric, integer, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_modificar_personal(IN p_id_personal integer, IN p_telefono character varying, IN p_salario numeric, IN p_dia_pago integer, IN p_horario character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE personal
    SET telefono = p_telefono,
        salario = p_salario,
        dia_pago_salario = p_dia_pago,
        horario = p_horario
    WHERE id_personal = p_id_personal;
END;
$$;


--
-- Name: sp_registrar_asistencia(character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_registrar_asistencia(IN p_clave_ingreso character varying)
    LANGUAGE plpgsql
    AS $$
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

    -- 2. Validaciones de seguridad (Esto le mandarÃ¡ un error a C# automÃ¡ticamente)
    IF v_id_cliente IS NULL THEN
        RAISE EXCEPTION 'Clave incorrecta. No se encontrÃ³ al cliente.';
    END IF;

    IF v_estatus = 'Inactivo' THEN
        RAISE EXCEPTION 'Acceso denegado. El cliente estÃ¡ dado de baja.';
    END IF;

    -- 3. Si todo estÃ¡ bien, registramos su entrada (la hora se pone sola)
    INSERT INTO asistencias (id_cliente) VALUES (v_id_cliente);
END;
$$;


--
-- Name: sp_registrar_pago(integer, integer, numeric, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_registrar_pago(IN p_id_cliente integer, IN p_id_recepcionista integer, IN p_monto numeric, IN p_tipo character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_membresia integer;
    v_tarifa numeric(10,2);
    v_activo boolean;
    v_referencia_renovacion integer;
BEGIN
    IF p_tipo IS NULL
       OR p_tipo NOT IN ('Mensualidad', 'Anualidad') THEN
        RAISE EXCEPTION 'Tipo de pago invÃ¡lido';
    END IF;

    -- Serializa los pagos del mismo cliente.
    SELECT id_membresia
    INTO v_id_membresia
    FROM public.clientes
    WHERE id_cliente = p_id_cliente
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El cliente no existe';
    END IF;

    -- Mantiene estable la tarifa hasta finalizar la transacciÃ³n.
    SELECT
        CASE
            WHEN p_tipo = 'Mensualidad' THEN costo_mensual
            ELSE costo_anualidad
        END,
        activo
    INTO v_tarifa, v_activo
    FROM public.membresias
    WHERE id_membresia = v_id_membresia
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La membresÃ­a no existe';
    END IF;

    IF NOT v_activo THEN
        RAISE EXCEPTION 'La membresÃ­a estÃ¡ inactiva';
    END IF;

    IF v_tarifa <= 0 THEN
        RAISE EXCEPTION
            'Este flujo requiere una tarifa mayor que cero';
    END IF;

    IF p_monto IS DISTINCT FROM v_tarifa THEN
        RAISE EXCEPTION
            'El monto no coincide con la tarifa oficial: %',
            v_tarifa;
    END IF;

    SELECT id_pago
    INTO v_referencia_renovacion
    FROM public.historial_pagos
    WHERE id_cliente = p_id_cliente
      AND tipo_pago = p_tipo
    ORDER BY fecha_transaccion DESC, id_pago DESC
    LIMIT 1;

    INSERT INTO public.historial_pagos (
        id_cliente,
        id_recepcionista,
        monto_pagado,
        tipo_pago,
        concepto,
        referencia_renovacion
    )
    VALUES (
        p_id_cliente,
        p_id_recepcionista,
        v_tarifa,
        p_tipo,
        p_tipo,
        v_referencia_renovacion
    );

    IF p_tipo = 'Mensualidad' THEN
        UPDATE public.clientes
        SET fecha_pago_mensual =
            CASE
                WHEN fecha_pago_mensual IS NULL
                    THEN CURRENT_DATE
                WHEN fecha_pago_mensual + INTERVAL '1 month'
                     > CURRENT_DATE
                    THEN fecha_pago_mensual + INTERVAL '1 month'
                ELSE CURRENT_DATE
            END
        WHERE id_cliente = p_id_cliente;
    ELSE
        UPDATE public.clientes
        SET fecha_pago_anualidad =
            CASE
                WHEN fecha_pago_anualidad IS NULL
                    THEN CURRENT_DATE
                WHEN fecha_pago_anualidad + INTERVAL '1 year'
                     > CURRENT_DATE
                    THEN fecha_pago_anualidad + INTERVAL '1 year'
                ELSE CURRENT_DATE
            END
        WHERE id_cliente = p_id_cliente;
    END IF;
END;
$$;


--
-- Name: sp_registrar_pago_idempotente(uuid, integer, integer, character varying, integer, boolean); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_registrar_pago_idempotente(IN p_clave uuid, IN p_id_cliente integer, IN p_id_recepcionista integer, IN p_tipo character varying, INOUT p_id_pago integer, INOUT p_repetido boolean)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_filas INTEGER;
    v_cliente INTEGER;
    v_id_membresia INTEGER;
    v_tarifa NUMERIC;
    v_activo BOOLEAN;
    v_clave_cliente INTEGER;
    v_clave_tipo VARCHAR;
    v_pago_existente INTEGER;
    v_referencia INTEGER;
BEGIN
    IF p_clave IS NULL
       OR p_id_cliente IS NULL
       OR p_id_cliente <= 0
       OR p_id_recepcionista IS NULL
       OR p_id_recepcionista <= 0
       OR p_tipo IS NULL
       OR p_tipo NOT IN ('Mensualidad', 'Anualidad')
    THEN
        RAISE EXCEPTION 'Datos del pago invÃ¡lidos';
    END IF;

    p_id_pago := NULL;
    p_repetido := FALSE;

    -- Reservar la operaciÃ³n de forma atÃ³mica.
    INSERT INTO public.pagos_idempotencia (
        clave_idempotencia,
        id_cliente,
        tipo_pago
    )
    VALUES (
        p_clave,
        p_id_cliente,
        p_tipo
    )
    ON CONFLICT (clave_idempotencia) DO NOTHING;

    GET DIAGNOSTICS v_filas = ROW_COUNT;

    -- Si la clave existe, comprobar la operaciÃ³n original.
    IF v_filas = 0 THEN
        SELECT id_cliente, tipo_pago, id_pago
        INTO v_clave_cliente, v_clave_tipo, v_pago_existente
        FROM public.pagos_idempotencia
        WHERE clave_idempotencia = p_clave
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'No se encontrÃ³ la operaciÃ³n reservada';
        END IF;

        IF v_clave_cliente IS DISTINCT FROM p_id_cliente
           OR v_clave_tipo IS DISTINCT FROM p_tipo
        THEN
            RAISE EXCEPTION
                'La clave pertenece a una operaciÃ³n diferente';
        END IF;

        IF v_pago_existente IS NULL THEN
            RAISE EXCEPTION 'OperaciÃ³n incompleta';
        END IF;

        p_id_pago := v_pago_existente;
        p_repetido := TRUE;
        RETURN;
    END IF;

    -- Verificar recepcionista activo.
    PERFORM 1
    FROM public.personal p
    JOIN public.usuarios u ON u.id_usuario = p.id_usuario
    JOIN public.roles r ON r.id_rol = u.id_rol
    WHERE p.id_personal = p_id_recepcionista
      AND u.estatus = 'Activo'
      AND r.nombre = 'Recepcionista'
    FOR SHARE OF p, u;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Recepcionista no autorizado';
    END IF;

    -- Bloquear al cliente para serializar sus pagos.
    SELECT c.id_cliente, c.id_membresia
    INTO v_cliente, v_id_membresia
    FROM public.clientes c
    WHERE c.id_cliente = p_id_cliente
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El cliente no existe';
    END IF;

    -- Obtener la tarifa oficial.
    SELECT
        CASE
            WHEN p_tipo = 'Mensualidad'
                THEN m.costo_mensual
            ELSE m.costo_anualidad
        END,
        m.activo
    INTO v_tarifa, v_activo
    FROM public.membresias m
    WHERE m.id_membresia = v_id_membresia
    FOR SHARE;

    IF NOT FOUND OR NOT COALESCE(v_activo, FALSE) THEN
        RAISE EXCEPTION 'La membresÃ­a no existe o estÃ¡ inactiva';
    END IF;

    IF v_tarifa IS NULL OR v_tarifa <= 0 THEN
        RAISE EXCEPTION 'La tarifa oficial no es vÃ¡lida';
    END IF;

    -- RelaciÃ³n con el pago anterior.
    SELECT h.id_pago
    INTO v_referencia
    FROM public.historial_pagos h
    WHERE h.id_cliente = p_id_cliente
      AND h.tipo_pago = p_tipo
    ORDER BY h.fecha_transaccion DESC, h.id_pago DESC
    LIMIT 1;

    -- Registrar el importe oficial y obtener su ID exacto.
    INSERT INTO public.historial_pagos (
        id_cliente,
        id_recepcionista,
        monto_pagado,
        tipo_pago,
        concepto,
        referencia_renovacion
    )
    VALUES (
        p_id_cliente,
        p_id_recepcionista,
        v_tarifa,
        p_tipo,
        p_tipo,
        v_referencia
    )
    RETURNING id_pago INTO p_id_pago;

    -- Actualizar la vigencia una sola vez.
    IF p_tipo = 'Mensualidad' THEN
        UPDATE public.clientes
        SET fecha_pago_mensual =
            CASE
                WHEN fecha_pago_mensual IS NULL
                    THEN CURRENT_DATE
                WHEN fecha_pago_mensual + INTERVAL '1 month'
                     > CURRENT_DATE
                    THEN (fecha_pago_mensual + INTERVAL '1 month')::date
                ELSE CURRENT_DATE
            END
        WHERE id_cliente = p_id_cliente;
    ELSE
        UPDATE public.clientes
        SET fecha_pago_anualidad =
            CASE
                WHEN fecha_pago_anualidad IS NULL
                    THEN CURRENT_DATE
                WHEN fecha_pago_anualidad + INTERVAL '1 year'
                     > CURRENT_DATE
                    THEN (fecha_pago_anualidad + INTERVAL '1 year')::date
                ELSE CURRENT_DATE
            END
        WHERE id_cliente = p_id_cliente;
    END IF;

    -- Asociar la clave con el pago realizado.
    UPDATE public.pagos_idempotencia
    SET id_pago = p_id_pago
    WHERE clave_idempotencia = p_clave;
END;
$$;


--
-- Name: sp_vincular_google(character varying, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_vincular_google(IN p_correo character varying, IN p_google_id character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE usuarios
    SET google_id = p_google_id
    WHERE correo = p_correo;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: asistencias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asistencias (
    id_asistencia_registro integer NOT NULL,
    id_cliente integer NOT NULL,
    fecha_hora timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    estado_acceso character varying(20) DEFAULT 'Aprobado'::character varying NOT NULL,
    origen_registro character varying(30) DEFAULT 'LectorCodigo'::character varying NOT NULL,
    CONSTRAINT asistencias_estado_acceso_check CHECK (((estado_acceso)::text = ANY (ARRAY[('Aprobado'::character varying)::text, ('Rechazado'::character varying)::text])))
);


--
-- Name: asistencias_id_asistencia_registro_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.asistencias_id_asistencia_registro_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asistencias_id_asistencia_registro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.asistencias_id_asistencia_registro_seq OWNED BY public.asistencias.id_asistencia_registro;


--
-- Name: bitacora_auditoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bitacora_auditoria (
    id_bitacora integer NOT NULL,
    id_usuario_app integer,
    tabla_afectada character varying(50) NOT NULL,
    accion_realizada character varying(10) NOT NULL,
    datos_viejos jsonb,
    datos_nuevos jsonb,
    fecha_auditoria timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT bitacora_auditoria_accion_realizada_check CHECK (((accion_realizada)::text = ANY (ARRAY[('INSERT'::character varying)::text, ('UPDATE'::character varying)::text, ('DELETE'::character varying)::text])))
);


--
-- Name: bitacora_auditoria_id_bitacora_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bitacora_auditoria_id_bitacora_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bitacora_auditoria_id_bitacora_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bitacora_auditoria_id_bitacora_seq OWNED BY public.bitacora_auditoria.id_bitacora;


--
-- Name: clientes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes (
    id_cliente integer NOT NULL,
    id_usuario integer NOT NULL,
    id_asistencia character varying(20) NOT NULL,
    nombre_completo character varying(150) NOT NULL,
    telefono character varying(20) NOT NULL,
    foto_url character varying(255),
    pdf_contrato character varying(255),
    costo_mensual_acordado numeric(10,2) NOT NULL,
    costo_anual_acordado numeric(10,2) NOT NULL,
    fecha_pago_mensual date,
    fecha_pago_anualidad date,
    fecha_alta date DEFAULT CURRENT_DATE NOT NULL,
    id_membresia integer NOT NULL,
    id_entrenador integer,
    codigo_acceso character varying(20),
    CONSTRAINT clientes_costo_anual_acordado_check CHECK ((costo_anual_acordado >= (0)::numeric)),
    CONSTRAINT clientes_costo_mensual_acordado_check CHECK ((costo_mensual_acordado >= (0)::numeric))
);


--
-- Name: clientes_id_cliente_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_id_cliente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_id_cliente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_id_cliente_seq OWNED BY public.clientes.id_cliente;


--
-- Name: dias_rutina; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dias_rutina (
    id_dia integer NOT NULL,
    dia character varying(20) NOT NULL,
    id_rutina integer NOT NULL
);


--
-- Name: dias_rutina_id_dia_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dias_rutina_id_dia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dias_rutina_id_dia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dias_rutina_id_dia_seq OWNED BY public.dias_rutina.id_dia;


--
-- Name: ejercicios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ejercicios (
    id_ejercicio integer NOT NULL,
    nombre character varying(120) NOT NULL,
    descripcion character varying(500),
    estado boolean DEFAULT true NOT NULL,
    imagen_url text
);


--
-- Name: ejercicios_id_ejercicio_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ejercicios_id_ejercicio_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ejercicios_id_ejercicio_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ejercicios_id_ejercicio_seq OWNED BY public.ejercicios.id_ejercicio;


--
-- Name: ejercicios_rutina; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ejercicios_rutina (
    id_ejercicio_rutina integer NOT NULL,
    id_dia integer NOT NULL,
    id_ejercicio integer NOT NULL,
    series integer NOT NULL,
    repeticiones integer NOT NULL,
    orden integer NOT NULL
);


--
-- Name: ejercicios_rutina_id_ejercicio_rutina_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ejercicios_rutina_id_ejercicio_rutina_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ejercicios_rutina_id_ejercicio_rutina_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ejercicios_rutina_id_ejercicio_rutina_seq OWNED BY public.ejercicios_rutina.id_ejercicio_rutina;


--
-- Name: historial_pagos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.historial_pagos (
    id_pago integer NOT NULL,
    id_cliente integer NOT NULL,
    id_recepcionista integer NOT NULL,
    monto_pagado numeric(10,2) NOT NULL,
    tipo_pago character varying(20) NOT NULL,
    fecha_transaccion timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    concepto character varying(100),
    referencia_renovacion integer,
    CONSTRAINT historial_pagos_monto_pagado_check CHECK ((monto_pagado > (0)::numeric)),
    CONSTRAINT historial_pagos_tipo_pago_check CHECK (((tipo_pago)::text = ANY (ARRAY[('Mensualidad'::character varying)::text, ('Anualidad'::character varying)::text])))
);


--
-- Name: historial_pagos_id_pago_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.historial_pagos_id_pago_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: historial_pagos_id_pago_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.historial_pagos_id_pago_seq OWNED BY public.historial_pagos.id_pago;


--
-- Name: membresias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.membresias (
    id_membresia integer NOT NULL,
    nombre_plan character varying(100) NOT NULL,
    costo_mensual numeric(10,2) NOT NULL,
    costo_anualidad numeric(10,2) NOT NULL,
    descripcion text DEFAULT ''::text NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    CONSTRAINT membresias_costo_anualidad_check CHECK ((costo_anualidad >= (0)::numeric)),
    CONSTRAINT membresias_costo_mensual_check CHECK ((costo_mensual >= (0)::numeric))
);


--
-- Name: membresias_id_membresia_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.membresias_id_membresia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: membresias_id_membresia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.membresias_id_membresia_seq OWNED BY public.membresias.id_membresia;


--
-- Name: membresias_precios_historial; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.membresias_precios_historial (
    id_historial bigint NOT NULL,
    id_membresia integer NOT NULL,
    costo_mensual numeric(10,2) NOT NULL,
    costo_anualidad numeric(10,2) NOT NULL,
    registrado_en timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    id_usuario_app integer,
    origen character varying(20) NOT NULL,
    CONSTRAINT membresias_precios_historial_costo_anualidad_check CHECK ((costo_anualidad >= (0)::numeric)),
    CONSTRAINT membresias_precios_historial_costo_mensual_check CHECK ((costo_mensual >= (0)::numeric)),
    CONSTRAINT membresias_precios_historial_origen_check CHECK (((origen)::text = ANY ((ARRAY['CapturaInicial'::character varying, 'Creacion'::character varying, 'CambioPrecio'::character varying])::text[])))
);


--
-- Name: membresias_precios_historial_id_historial_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.membresias_precios_historial ALTER COLUMN id_historial ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.membresias_precios_historial_id_historial_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notificaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notificaciones (
    id_notificacion bigint NOT NULL,
    id_usuario integer NOT NULL,
    tipo character varying(40) DEFAULT 'MembresiaPorVencer'::character varying NOT NULL,
    titulo character varying(150) NOT NULL,
    mensaje text NOT NULL,
    fecha_vencimiento date NOT NULL,
    leida boolean DEFAULT false NOT NULL,
    fecha_lectura timestamp with time zone,
    creado_en timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_notificacion_lectura CHECK ((((leida = false) AND (fecha_lectura IS NULL)) OR ((leida = true) AND (fecha_lectura IS NOT NULL)))),
    CONSTRAINT chk_notificacion_mensaje CHECK ((NULLIF(TRIM(BOTH FROM mensaje), ''::text) IS NOT NULL)),
    CONSTRAINT chk_notificacion_tipo CHECK (((tipo)::text = 'MembresiaPorVencer'::text)),
    CONSTRAINT chk_notificacion_titulo CHECK ((NULLIF(TRIM(BOTH FROM titulo), ''::text) IS NOT NULL))
);


--
-- Name: notificaciones_id_notificacion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.notificaciones ALTER COLUMN id_notificacion ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.notificaciones_id_notificacion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pagos_idempotencia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pagos_idempotencia (
    clave_idempotencia uuid NOT NULL,
    id_cliente integer NOT NULL,
    tipo_pago character varying(20) NOT NULL,
    id_pago integer,
    fecha_creacion timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_idempotencia_tipo CHECK (((tipo_pago)::text = ANY ((ARRAY['Mensualidad'::character varying, 'Anualidad'::character varying])::text[])))
);


--
-- Name: personal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.personal (
    id_personal integer NOT NULL,
    id_usuario integer NOT NULL,
    nombre_completo character varying(150) NOT NULL,
    telefono character varying(20) NOT NULL,
    salario numeric(10,2) NOT NULL,
    dia_pago_salario integer NOT NULL,
    horario character varying(100) NOT NULL,
    fecha_alta date DEFAULT CURRENT_DATE NOT NULL,
    fecha_baja date,
    motivo_baja text,
    fecha_actualizacion timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_personal_fecha_baja CHECK (((fecha_baja IS NULL) OR (fecha_baja >= fecha_alta))),
    CONSTRAINT personal_dia_pago_salario_check CHECK (((dia_pago_salario >= 1) AND (dia_pago_salario <= 31))),
    CONSTRAINT personal_salario_check CHECK ((salario >= (0)::numeric))
);


--
-- Name: personal_asistencias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.personal_asistencias (
    id_asistencia_personal bigint NOT NULL,
    id_personal integer NOT NULL,
    fecha date NOT NULL,
    hora_entrada time without time zone NOT NULL,
    hora_salida time without time zone,
    registrado_por integer NOT NULL,
    fecha_registro timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    salida_registrada_por integer,
    fecha_registro_salida timestamp with time zone,
    CONSTRAINT chk_asistencia_horario CHECK (((hora_salida IS NULL) OR (hora_salida >= hora_entrada)))
);


--
-- Name: personal_asistencias_id_asistencia_personal_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.personal_asistencias_id_asistencia_personal_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: personal_asistencias_id_asistencia_personal_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.personal_asistencias_id_asistencia_personal_seq OWNED BY public.personal_asistencias.id_asistencia_personal;


--
-- Name: personal_id_personal_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.personal_id_personal_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: personal_id_personal_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.personal_id_personal_seq OWNED BY public.personal.id_personal;


--
-- Name: personal_nomina_pagos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.personal_nomina_pagos (
    id_pago bigint NOT NULL,
    id_personal integer NOT NULL,
    id_salario bigint NOT NULL,
    periodo_inicio date NOT NULL,
    periodo_fin date NOT NULL,
    monto numeric(12,2) NOT NULL,
    fecha_pago date NOT NULL,
    metodo character varying(20) NOT NULL,
    referencia character varying(100),
    observaciones text,
    estado character varying(15) DEFAULT 'Pagado'::character varying NOT NULL,
    registrado_por integer NOT NULL,
    cancelado_por integer,
    fecha_cancelacion timestamp with time zone,
    motivo_cancelacion text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_nomina_cancelacion CHECK ((((estado)::text <> 'Cancelado'::text) OR ((cancelado_por IS NOT NULL) AND (fecha_cancelacion IS NOT NULL) AND (NULLIF(TRIM(BOTH FROM motivo_cancelacion), ''::text) IS NOT NULL)))),
    CONSTRAINT chk_nomina_periodo CHECK ((periodo_fin >= periodo_inicio)),
    CONSTRAINT personal_nomina_pagos_estado_check CHECK (((estado)::text = ANY (ARRAY[('Pagado'::character varying)::text, ('Cancelado'::character varying)::text]))),
    CONSTRAINT personal_nomina_pagos_metodo_check CHECK (((metodo)::text = ANY (ARRAY[('Efectivo'::character varying)::text, ('Transferencia'::character varying)::text]))),
    CONSTRAINT personal_nomina_pagos_monto_check CHECK ((monto > (0)::numeric))
);


--
-- Name: personal_nomina_pagos_id_pago_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.personal_nomina_pagos ALTER COLUMN id_pago ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.personal_nomina_pagos_id_pago_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: personal_salarios_historial; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.personal_salarios_historial (
    id_salario bigint NOT NULL,
    id_personal integer NOT NULL,
    monto numeric(12,2) NOT NULL,
    periodicidad character varying(20) NOT NULL,
    vigente_desde date NOT NULL,
    vigente_hasta date,
    motivo text,
    registrado_por integer,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_salario_fechas CHECK (((vigente_hasta IS NULL) OR (vigente_hasta >= vigente_desde))),
    CONSTRAINT personal_salarios_historial_monto_check CHECK ((monto >= (0)::numeric)),
    CONSTRAINT personal_salarios_historial_periodicidad_check CHECK (((periodicidad)::text = ANY (ARRAY[('Semanal'::character varying)::text, ('Quincenal'::character varying)::text, ('Mensual'::character varying)::text])))
);


--
-- Name: personal_salarios_historial_id_salario_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.personal_salarios_historial ALTER COLUMN id_salario ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.personal_salarios_historial_id_salario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: progreso; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.progreso (
    id_progreso integer NOT NULL,
    id_cliente integer NOT NULL,
    id_ejercicio integer NOT NULL,
    peso_utilizado numeric(10,2) NOT NULL,
    fecha_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_entrenamiento date DEFAULT CURRENT_DATE NOT NULL,
    CONSTRAINT chk_progreso_peso CHECK ((peso_utilizado > (0)::numeric))
);


--
-- Name: progreso_id_progreso_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.progreso_id_progreso_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: progreso_id_progreso_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.progreso_id_progreso_seq OWNED BY public.progreso.id_progreso;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id_rol integer CONSTRAINT rol_id_rol_not_null NOT NULL,
    nombre character varying(50) CONSTRAINT rol_nombre_not_null NOT NULL
);


--
-- Name: rol_id_rol_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rol_id_rol_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rol_id_rol_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rol_id_rol_seq OWNED BY public.roles.id_rol;


--
-- Name: rutinas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rutinas (
    id_rutina integer NOT NULL,
    nombre character varying(120) NOT NULL,
    descripcion character varying(500),
    id_cliente integer NOT NULL
);


--
-- Name: rutinas_id_rutina_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rutinas_id_rutina_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rutinas_id_rutina_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rutinas_id_rutina_seq OWNED BY public.rutinas.id_rutina;


--
-- Name: system_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_versions (
    id integer NOT NULL,
    version character varying(20) NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: system_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.system_versions_id_seq OWNED BY public.system_versions.id;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuarios (
    id_usuario integer NOT NULL,
    correo character varying(150) NOT NULL,
    contrasena_hash character varying(255) NOT NULL,
    estatus character varying(20) DEFAULT 'Activo'::character varying NOT NULL,
    id_rol integer NOT NULL,
    google_id character varying(255),
    CONSTRAINT usuarios_estatus_check CHECK (((estatus)::text = ANY (ARRAY[('Activo'::character varying)::text, ('Inactivo'::character varying)::text])))
);


--
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usuarios_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usuarios_id_usuario_seq OWNED BY public.usuarios.id_usuario;


--
-- Name: vw_admin_asistencias_dia; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_admin_asistencias_dia AS
 SELECT count(*) AS asistencias_dia
   FROM public.asistencias
  WHERE (((estado_acceso)::text = 'Aprobado'::text) AND (fecha_hora >= (CURRENT_DATE)::timestamp without time zone) AND (fecha_hora < ((CURRENT_DATE + 1))::timestamp without time zone));


--
-- Name: vw_admin_clientes; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_admin_clientes AS
 WITH datos AS (
         SELECT c.id_cliente,
            c.nombre_completo,
            u.correo,
            c.telefono,
            c.id_membresia,
            m.nombre_plan,
            u.estatus,
            GREATEST(((c.fecha_pago_mensual + '1 mon'::interval))::date, ((c.fecha_pago_anualidad + '1 year'::interval))::date) AS fecha_vencimiento
           FROM ((public.clientes c
             JOIN public.usuarios u ON ((u.id_usuario = c.id_usuario)))
             JOIN public.membresias m ON ((m.id_membresia = c.id_membresia)))
        )
 SELECT id_cliente,
    nombre_completo,
    correo,
    telefono,
    id_membresia,
    nombre_plan,
    estatus,
        CASE
            WHEN (fecha_vencimiento IS NULL) THEN 'SinPagos'::text
            WHEN (fecha_vencimiento >= CURRENT_DATE) THEN 'Vigente'::text
            ELSE 'Vencida'::text
        END AS vigencia,
    fecha_vencimiento
   FROM datos;


--
-- Name: vw_admin_membresias_activas; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_admin_membresias_activas AS
 SELECT count(*) AS membresias_activas
   FROM (public.clientes c
     JOIN public.usuarios u ON ((u.id_usuario = c.id_usuario)))
  WHERE (((u.estatus)::text = 'Activo'::text) AND ((((c.fecha_pago_mensual + '1 mon'::interval))::date >= CURRENT_DATE) OR (((c.fecha_pago_anualidad + '1 year'::interval))::date >= CURRENT_DATE)));


--
-- Name: vw_admin_pagos_registrados; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_admin_pagos_registrados AS
 SELECT count(*) AS pagos_registrados
   FROM public.historial_pagos;


--
-- Name: vw_admin_total_clientes; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_admin_total_clientes AS
 SELECT count(*) AS total_clientes
   FROM public.clientes;


--
-- Name: vw_asistencias_lista; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_asistencias_lista AS
 SELECT a.id_asistencia_registro,
    c.id_asistencia AS clave_ingreso,
    c.nombre_completo AS nombre_cliente,
    a.fecha_hora
   FROM (public.asistencias a
     JOIN public.clientes c ON ((a.id_cliente = c.id_cliente)));


--
-- Name: vw_clientes_lista; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_clientes_lista AS
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
   FROM (((public.clientes c
     JOIN public.usuarios u ON ((c.id_usuario = u.id_usuario)))
     JOIN public.membresias m ON ((c.id_membresia = m.id_membresia)))
     LEFT JOIN public.personal p ON ((c.id_entrenador = p.id_personal)));


--
-- Name: vw_clientes_por_entrenador; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_clientes_por_entrenador AS
 SELECT c.id_entrenador,
    p.nombre_completo AS nombre_entrenador,
    c.id_cliente,
    c.id_usuario,
    c.nombre_completo AS nombre_cliente,
    u.correo,
    c.telefono,
    u.estatus
   FROM ((public.clientes c
     JOIN public.usuarios u ON ((c.id_usuario = u.id_usuario)))
     JOIN public.personal p ON ((c.id_entrenador = p.id_personal)))
  WHERE (c.id_entrenador IS NOT NULL);


--
-- Name: vw_historial_pagos; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_historial_pagos AS
 SELECT p.id_pago,
    p.fecha_transaccion,
    c.nombre_completo AS nombre_cliente,
    rec.nombre_completo AS cobrado_por,
    p.monto_pagado,
    p.tipo_pago
   FROM ((public.historial_pagos p
     JOIN public.clientes c ON ((p.id_cliente = c.id_cliente)))
     JOIN public.personal rec ON ((p.id_recepcionista = rec.id_personal)));


--
-- Name: vw_membresias_lista; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_membresias_lista AS
 SELECT id_membresia,
    nombre_plan,
    costo_mensual,
    costo_anualidad
   FROM public.membresias;


--
-- Name: vw_personal_lista; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_personal_lista AS
 SELECT p.id_personal,
    u.id_usuario,
    p.nombre_completo,
    u.correo,
    p.telefono,
    r.nombre AS nombre_rol,
    p.horario,
    p.salario,
    u.estatus
   FROM ((public.personal p
     JOIN public.usuarios u ON ((p.id_usuario = u.id_usuario)))
     JOIN public.roles r ON ((u.id_rol = r.id_rol)));


--
-- Name: vw_reporte_auditoria; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_reporte_auditoria AS
 SELECT b.id_bitacora,
    b.id_usuario_app,
    u.correo AS usuario_que_modifico,
    b.tabla_afectada,
    b.accion_realizada,
    to_char(b.fecha_auditoria, 'DD/MM/YYYY HH24:MI'::text) AS fecha_auditoria,
    b.datos_viejos,
    b.datos_nuevos
   FROM (public.bitacora_auditoria b
     LEFT JOIN public.usuarios u ON ((b.id_usuario_app = u.id_usuario)))
  ORDER BY b.fecha_auditoria DESC;


--
-- Name: vw_usuarios_login; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_usuarios_login AS
 SELECT u.id_usuario,
    u.correo,
    u.contrasena_hash,
    u.google_id,
    u.estatus,
    u.id_rol,
    r.nombre AS nombre_rol,
    (COALESCE(p.nombre_completo, c.nombre_completo))::character varying AS nombre_perfil
   FROM (((public.usuarios u
     JOIN public.roles r ON ((u.id_rol = r.id_rol)))
     LEFT JOIN public.personal p ON ((u.id_usuario = p.id_usuario)))
     LEFT JOIN public.clientes c ON ((u.id_usuario = c.id_usuario)));


--
-- Name: asistencias id_asistencia_registro; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asistencias ALTER COLUMN id_asistencia_registro SET DEFAULT nextval('public.asistencias_id_asistencia_registro_seq'::regclass);


--
-- Name: bitacora_auditoria id_bitacora; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bitacora_auditoria ALTER COLUMN id_bitacora SET DEFAULT nextval('public.bitacora_auditoria_id_bitacora_seq'::regclass);


--
-- Name: clientes id_cliente; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes ALTER COLUMN id_cliente SET DEFAULT nextval('public.clientes_id_cliente_seq'::regclass);


--
-- Name: dias_rutina id_dia; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dias_rutina ALTER COLUMN id_dia SET DEFAULT nextval('public.dias_rutina_id_dia_seq'::regclass);


--
-- Name: ejercicios id_ejercicio; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ejercicios ALTER COLUMN id_ejercicio SET DEFAULT nextval('public.ejercicios_id_ejercicio_seq'::regclass);


--
-- Name: ejercicios_rutina id_ejercicio_rutina; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ejercicios_rutina ALTER COLUMN id_ejercicio_rutina SET DEFAULT nextval('public.ejercicios_rutina_id_ejercicio_rutina_seq'::regclass);


--
-- Name: historial_pagos id_pago; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_pagos ALTER COLUMN id_pago SET DEFAULT nextval('public.historial_pagos_id_pago_seq'::regclass);


--
-- Name: membresias id_membresia; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membresias ALTER COLUMN id_membresia SET DEFAULT nextval('public.membresias_id_membresia_seq'::regclass);


--
-- Name: personal id_personal; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal ALTER COLUMN id_personal SET DEFAULT nextval('public.personal_id_personal_seq'::regclass);


--
-- Name: personal_asistencias id_asistencia_personal; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_asistencias ALTER COLUMN id_asistencia_personal SET DEFAULT nextval('public.personal_asistencias_id_asistencia_personal_seq'::regclass);


--
-- Name: progreso id_progreso; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.progreso ALTER COLUMN id_progreso SET DEFAULT nextval('public.progreso_id_progreso_seq'::regclass);


--
-- Name: roles id_rol; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id_rol SET DEFAULT nextval('public.rol_id_rol_seq'::regclass);


--
-- Name: rutinas id_rutina; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rutinas ALTER COLUMN id_rutina SET DEFAULT nextval('public.rutinas_id_rutina_seq'::regclass);


--
-- Name: system_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_versions ALTER COLUMN id SET DEFAULT nextval('public.system_versions_id_seq'::regclass);


--
-- Name: usuarios id_usuario; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id_usuario SET DEFAULT nextval('public.usuarios_id_usuario_seq'::regclass);


--
-- Name: asistencias asistencias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asistencias
    ADD CONSTRAINT asistencias_pkey PRIMARY KEY (id_asistencia_registro);


--
-- Name: bitacora_auditoria bitacora_auditoria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bitacora_auditoria
    ADD CONSTRAINT bitacora_auditoria_pkey PRIMARY KEY (id_bitacora);


--
-- Name: clientes clientes_id_asistencia_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_id_asistencia_key UNIQUE (id_asistencia);


--
-- Name: clientes clientes_id_usuario_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_id_usuario_key UNIQUE (id_usuario);


--
-- Name: clientes clientes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_pkey PRIMARY KEY (id_cliente);


--
-- Name: dias_rutina dias_rutina_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dias_rutina
    ADD CONSTRAINT dias_rutina_pkey PRIMARY KEY (id_dia);


--
-- Name: ejercicios ejercicios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ejercicios
    ADD CONSTRAINT ejercicios_pkey PRIMARY KEY (id_ejercicio);


--
-- Name: ejercicios_rutina ejercicios_rutina_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ejercicios_rutina
    ADD CONSTRAINT ejercicios_rutina_pkey PRIMARY KEY (id_ejercicio_rutina);


--
-- Name: historial_pagos historial_pagos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_pagos
    ADD CONSTRAINT historial_pagos_pkey PRIMARY KEY (id_pago);


--
-- Name: membresias membresias_nombre_plan_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membresias
    ADD CONSTRAINT membresias_nombre_plan_key UNIQUE (nombre_plan);


--
-- Name: membresias membresias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membresias
    ADD CONSTRAINT membresias_pkey PRIMARY KEY (id_membresia);


--
-- Name: membresias_precios_historial membresias_precios_historial_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membresias_precios_historial
    ADD CONSTRAINT membresias_precios_historial_pkey PRIMARY KEY (id_historial);


--
-- Name: notificaciones notificaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notificaciones
    ADD CONSTRAINT notificaciones_pkey PRIMARY KEY (id_notificacion);


--
-- Name: pagos_idempotencia pagos_idempotencia_id_pago_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos_idempotencia
    ADD CONSTRAINT pagos_idempotencia_id_pago_key UNIQUE (id_pago);


--
-- Name: pagos_idempotencia pagos_idempotencia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos_idempotencia
    ADD CONSTRAINT pagos_idempotencia_pkey PRIMARY KEY (clave_idempotencia);


--
-- Name: personal_asistencias personal_asistencias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_asistencias
    ADD CONSTRAINT personal_asistencias_pkey PRIMARY KEY (id_asistencia_personal);


--
-- Name: personal personal_id_usuario_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal
    ADD CONSTRAINT personal_id_usuario_key UNIQUE (id_usuario);


--
-- Name: personal_nomina_pagos personal_nomina_pagos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_nomina_pagos
    ADD CONSTRAINT personal_nomina_pagos_pkey PRIMARY KEY (id_pago);


--
-- Name: personal personal_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal
    ADD CONSTRAINT personal_pkey PRIMARY KEY (id_personal);


--
-- Name: personal_salarios_historial personal_salarios_historial_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_salarios_historial
    ADD CONSTRAINT personal_salarios_historial_pkey PRIMARY KEY (id_salario);


--
-- Name: progreso progreso_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.progreso
    ADD CONSTRAINT progreso_pkey PRIMARY KEY (id_progreso);


--
-- Name: roles rol_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT rol_nombre_key UNIQUE (nombre);


--
-- Name: roles rol_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id_rol);


--
-- Name: rutinas rutinas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rutinas
    ADD CONSTRAINT rutinas_pkey PRIMARY KEY (id_rutina);


--
-- Name: system_versions system_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_versions
    ADD CONSTRAINT system_versions_pkey PRIMARY KEY (id);


--
-- Name: personal_asistencias uq_asistencia_personal_fecha; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_asistencias
    ADD CONSTRAINT uq_asistencia_personal_fecha UNIQUE (id_personal, fecha);


--
-- Name: clientes uq_clientes_codigo_acceso; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT uq_clientes_codigo_acceso UNIQUE (codigo_acceso);


--
-- Name: notificaciones uq_notificacion_vencimiento; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notificaciones
    ADD CONSTRAINT uq_notificacion_vencimiento UNIQUE (id_usuario, tipo, fecha_vencimiento);


--
-- Name: usuarios usuarios_correo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_correo_key UNIQUE (correo);


--
-- Name: usuarios usuarios_google_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_google_id_key UNIQUE (google_id);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id_usuario);


--
-- Name: idx_asistencias_id_cliente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_asistencias_id_cliente ON public.asistencias USING btree (id_cliente);


--
-- Name: idx_clientes_codigo_acceso; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clientes_codigo_acceso ON public.clientes USING btree (codigo_acceso);


--
-- Name: idx_clientes_id_entrenador; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clientes_id_entrenador ON public.clientes USING btree (id_entrenador);


--
-- Name: idx_clientes_nombre_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clientes_nombre_trgm ON public.clientes USING gin (nombre_completo public.gin_trgm_ops);


--
-- Name: idx_ejercicios_nombre; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ejercicios_nombre ON public.ejercicios USING btree (nombre);


--
-- Name: idx_historial_pagos_id_cliente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_historial_pagos_id_cliente ON public.historial_pagos USING btree (id_cliente);


--
-- Name: idx_notificaciones_usuario_no_leidas; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notificaciones_usuario_no_leidas ON public.notificaciones USING btree (id_usuario) WHERE (leida = false);


--
-- Name: idx_notificaciones_usuario_recientes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notificaciones_usuario_recientes ON public.notificaciones USING btree (id_usuario, creado_en DESC, id_notificacion DESC);


--
-- Name: idx_personal_asistencias_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_personal_asistencias_fecha ON public.personal_asistencias USING btree (fecha);


--
-- Name: idx_personal_asistencias_personal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_personal_asistencias_personal ON public.personal_asistencias USING btree (id_personal, fecha DESC);


--
-- Name: idx_progreso_cliente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_progreso_cliente ON public.progreso USING btree (id_cliente);


--
-- Name: idx_progreso_cliente_ejercicio_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_progreso_cliente_ejercicio_fecha ON public.progreso USING btree (id_cliente, id_ejercicio, fecha_registro DESC);


--
-- Name: idx_progreso_ejercicio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_progreso_ejercicio ON public.progreso USING btree (id_ejercicio);


--
-- Name: idx_usuarios_correo_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_usuarios_correo_trgm ON public.usuarios USING gin (correo public.gin_trgm_ops);


--
-- Name: ix_membresias_precios_historial_plan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_membresias_precios_historial_plan ON public.membresias_precios_historial USING btree (id_membresia, id_historial DESC);


--
-- Name: ix_nomina_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_nomina_fecha ON public.personal_nomina_pagos USING btree (fecha_pago);


--
-- Name: ux_nomina_periodo_pagado; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_nomina_periodo_pagado ON public.personal_nomina_pagos USING btree (id_personal, periodo_inicio, periodo_fin) WHERE ((estado)::text = 'Pagado'::text);


--
-- Name: ux_salario_vigente; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_salario_vigente ON public.personal_salarios_historial USING btree (id_personal) WHERE (vigente_hasta IS NULL);


--
-- Name: clientes trg_auditoria_clientes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auditoria_clientes AFTER INSERT OR DELETE OR UPDATE ON public.clientes FOR EACH ROW EXECUTE FUNCTION public.fn_registrar_auditoria();


--
-- Name: historial_pagos trg_auditoria_pagos; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auditoria_pagos AFTER INSERT OR DELETE OR UPDATE ON public.historial_pagos FOR EACH ROW EXECUTE FUNCTION public.fn_registrar_auditoria();


--
-- Name: personal trg_auditoria_personal; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auditoria_personal AFTER INSERT OR DELETE OR UPDATE ON public.personal FOR EACH ROW EXECUTE FUNCTION public.fn_registrar_auditoria();


--
-- Name: usuarios trg_auditoria_usuarios; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auditoria_usuarios AFTER INSERT OR DELETE OR UPDATE ON public.usuarios FOR EACH ROW EXECUTE FUNCTION public.fn_registrar_auditoria();


--
-- Name: clientes trg_generar_codigo_acceso; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_generar_codigo_acceso BEFORE INSERT ON public.clientes FOR EACH ROW EXECUTE FUNCTION public.fn_generar_codigo_acceso();


--
-- Name: membresias trg_historial_precio_membresia; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_historial_precio_membresia AFTER INSERT OR UPDATE ON public.membresias FOR EACH ROW EXECUTE FUNCTION public.fn_historial_precio_membresia();


--
-- Name: asistencias fk_cliente_asistencia; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asistencias
    ADD CONSTRAINT fk_cliente_asistencia FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE RESTRICT;


--
-- Name: historial_pagos fk_cliente_pago; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_pagos
    ADD CONSTRAINT fk_cliente_pago FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE RESTRICT;


--
-- Name: dias_rutina fk_dias_rutina_rutina; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dias_rutina
    ADD CONSTRAINT fk_dias_rutina_rutina FOREIGN KEY (id_rutina) REFERENCES public.rutinas(id_rutina) ON DELETE CASCADE;


--
-- Name: ejercicios_rutina fk_ejercicios_rutina_dia; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ejercicios_rutina
    ADD CONSTRAINT fk_ejercicios_rutina_dia FOREIGN KEY (id_dia) REFERENCES public.dias_rutina(id_dia) ON DELETE CASCADE;


--
-- Name: ejercicios_rutina fk_ejercicios_rutina_ejercicio; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ejercicios_rutina
    ADD CONSTRAINT fk_ejercicios_rutina_ejercicio FOREIGN KEY (id_ejercicio) REFERENCES public.ejercicios(id_ejercicio) ON DELETE RESTRICT;


--
-- Name: clientes fk_entrenador_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT fk_entrenador_cliente FOREIGN KEY (id_entrenador) REFERENCES public.personal(id_personal) ON DELETE SET NULL;


--
-- Name: historial_pagos fk_historial_pagos_renovacion; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_pagos
    ADD CONSTRAINT fk_historial_pagos_renovacion FOREIGN KEY (referencia_renovacion) REFERENCES public.historial_pagos(id_pago);


--
-- Name: pagos_idempotencia fk_idempotencia_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos_idempotencia
    ADD CONSTRAINT fk_idempotencia_cliente FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE RESTRICT;


--
-- Name: pagos_idempotencia fk_idempotencia_pago; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagos_idempotencia
    ADD CONSTRAINT fk_idempotencia_pago FOREIGN KEY (id_pago) REFERENCES public.historial_pagos(id_pago) ON DELETE RESTRICT;


--
-- Name: clientes fk_membresia_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT fk_membresia_cliente FOREIGN KEY (id_membresia) REFERENCES public.membresias(id_membresia) ON DELETE RESTRICT;


--
-- Name: personal_asistencias fk_personal_asistencias_salida_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_asistencias
    ADD CONSTRAINT fk_personal_asistencias_salida_usuario FOREIGN KEY (salida_registrada_por) REFERENCES public.usuarios(id_usuario) ON DELETE RESTRICT;


--
-- Name: progreso fk_progreso_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.progreso
    ADD CONSTRAINT fk_progreso_cliente FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE RESTRICT;


--
-- Name: progreso fk_progreso_ejercicio; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.progreso
    ADD CONSTRAINT fk_progreso_ejercicio FOREIGN KEY (id_ejercicio) REFERENCES public.ejercicios(id_ejercicio) ON DELETE RESTRICT;


--
-- Name: historial_pagos fk_recepcionista_pago; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_pagos
    ADD CONSTRAINT fk_recepcionista_pago FOREIGN KEY (id_recepcionista) REFERENCES public.personal(id_personal) ON DELETE RESTRICT;


--
-- Name: usuarios fk_rol; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT fk_rol FOREIGN KEY (id_rol) REFERENCES public.roles(id_rol) ON DELETE RESTRICT;


--
-- Name: rutinas fk_rutina_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rutinas
    ADD CONSTRAINT fk_rutina_cliente FOREIGN KEY (id_cliente) REFERENCES public.clientes(id_cliente) ON DELETE CASCADE;


--
-- Name: clientes fk_usuario_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT fk_usuario_cliente FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario) ON DELETE RESTRICT;


--
-- Name: personal fk_usuario_personal; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal
    ADD CONSTRAINT fk_usuario_personal FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario) ON DELETE RESTRICT;


--
-- Name: membresias_precios_historial membresias_precios_historial_id_membresia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membresias_precios_historial
    ADD CONSTRAINT membresias_precios_historial_id_membresia_fkey FOREIGN KEY (id_membresia) REFERENCES public.membresias(id_membresia) ON DELETE RESTRICT;


--
-- Name: membresias_precios_historial membresias_precios_historial_id_usuario_app_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.membresias_precios_historial
    ADD CONSTRAINT membresias_precios_historial_id_usuario_app_fkey FOREIGN KEY (id_usuario_app) REFERENCES public.usuarios(id_usuario) ON DELETE RESTRICT;


--
-- Name: notificaciones notificaciones_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notificaciones
    ADD CONSTRAINT notificaciones_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario) ON DELETE RESTRICT;


--
-- Name: personal_asistencias personal_asistencias_id_personal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_asistencias
    ADD CONSTRAINT personal_asistencias_id_personal_fkey FOREIGN KEY (id_personal) REFERENCES public.personal(id_personal) ON DELETE RESTRICT;


--
-- Name: personal_asistencias personal_asistencias_registrado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_asistencias
    ADD CONSTRAINT personal_asistencias_registrado_por_fkey FOREIGN KEY (registrado_por) REFERENCES public.usuarios(id_usuario) ON DELETE RESTRICT;


--
-- Name: personal_nomina_pagos personal_nomina_pagos_cancelado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_nomina_pagos
    ADD CONSTRAINT personal_nomina_pagos_cancelado_por_fkey FOREIGN KEY (cancelado_por) REFERENCES public.usuarios(id_usuario);


--
-- Name: personal_nomina_pagos personal_nomina_pagos_id_personal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_nomina_pagos
    ADD CONSTRAINT personal_nomina_pagos_id_personal_fkey FOREIGN KEY (id_personal) REFERENCES public.personal(id_personal) ON DELETE RESTRICT;


--
-- Name: personal_nomina_pagos personal_nomina_pagos_id_salario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_nomina_pagos
    ADD CONSTRAINT personal_nomina_pagos_id_salario_fkey FOREIGN KEY (id_salario) REFERENCES public.personal_salarios_historial(id_salario) ON DELETE RESTRICT;


--
-- Name: personal_nomina_pagos personal_nomina_pagos_registrado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_nomina_pagos
    ADD CONSTRAINT personal_nomina_pagos_registrado_por_fkey FOREIGN KEY (registrado_por) REFERENCES public.usuarios(id_usuario);


--
-- Name: personal_salarios_historial personal_salarios_historial_id_personal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_salarios_historial
    ADD CONSTRAINT personal_salarios_historial_id_personal_fkey FOREIGN KEY (id_personal) REFERENCES public.personal(id_personal) ON DELETE RESTRICT;


--
-- Name: personal_salarios_historial personal_salarios_historial_registrado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_salarios_historial
    ADD CONSTRAINT personal_salarios_historial_registrado_por_fkey FOREIGN KEY (registrado_por) REFERENCES public.usuarios(id_usuario);


--
-- PostgreSQL database dump complete
--

\unrestrict a6gkNsHR9UdwgDbsohsQQbEQAFo7JU9t8WV7GUcHAs8oD0wArpuTgL9uYDMFkMC


