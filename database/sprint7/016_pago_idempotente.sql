
-- GymFlow Sprint 7
-- Migración 016: pagos con idempotencia
-- Ejecutar únicamente en gymflow_pruebas.
-- Conserva sp_registrar_pago y los pagos históricos.

BEGIN;

CREATE OR REPLACE PROCEDURE public.sp_registrar_pago_idempotente(
    IN p_clave UUID,
    IN p_id_cliente INTEGER,
    IN p_id_recepcionista INTEGER,
    IN p_tipo VARCHAR,
    INOUT p_id_pago INTEGER,
    INOUT p_repetido BOOLEAN
)
LANGUAGE plpgsql
AS $procedure$
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
        RAISE EXCEPTION 'Datos del pago inválidos';
    END IF;

    p_id_pago := NULL;
    p_repetido := FALSE;

    -- Reservar la operación de forma atómica.
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

    -- Si la clave existe, comprobar la operación original.
    IF v_filas = 0 THEN
        SELECT id_cliente, tipo_pago, id_pago
        INTO v_clave_cliente, v_clave_tipo, v_pago_existente
        FROM public.pagos_idempotencia
        WHERE clave_idempotencia = p_clave
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'No se encontró la operación reservada';
        END IF;

        IF v_clave_cliente IS DISTINCT FROM p_id_cliente
           OR v_clave_tipo IS DISTINCT FROM p_tipo
        THEN
            RAISE EXCEPTION
                'La clave pertenece a una operación diferente';
        END IF;

        IF v_pago_existente IS NULL THEN
            RAISE EXCEPTION 'Operación incompleta';
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
        RAISE EXCEPTION 'La membresía no existe o está inactiva';
    END IF;

    IF v_tarifa IS NULL OR v_tarifa <= 0 THEN
        RAISE EXCEPTION 'La tarifa oficial no es válida';
    END IF;

    -- Relación con el pago anterior.
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
$procedure$;

COMMIT;
