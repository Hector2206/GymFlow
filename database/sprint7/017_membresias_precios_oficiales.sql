
-- GYMFLOW SPRINT 7
-- 017: Membresias y tarifas oficiales
-- Preparado para migrar desde el esquema anterior.
-- No elimina membresias, clientes ni pagos.
-- Ejecutar primero en gymflow_pruebas para validar.

BEGIN;

-- =========================================
-- 1. AMPLIAR MEMBRESIAS
-- =========================================

ALTER TABLE public.membresias
    ADD COLUMN IF NOT EXISTS descripcion TEXT
        NOT NULL DEFAULT '';

ALTER TABLE public.membresias
    ADD COLUMN IF NOT EXISTS activo BOOLEAN
        NOT NULL DEFAULT TRUE;

-- Las membresias existentes permanecen activas.
-- No se modifican sus precios.

-- =========================================
-- 2. HISTORIAL DE PRECIOS
-- =========================================

CREATE TABLE IF NOT EXISTS
    public.membresias_precios_historial
(
    id_historial BIGSERIAL PRIMARY KEY,
    id_membresia INTEGER NOT NULL,
    costo_mensual NUMERIC(10,2) NOT NULL,
    costo_anualidad NUMERIC(10,2) NOT NULL,
    registrado_en TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP,
    id_usuario_app INTEGER NULL,
    origen VARCHAR(30) NOT NULL,

    CONSTRAINT fk_historial_membresia
        FOREIGN KEY (id_membresia)
        REFERENCES public.membresias(id_membresia)
        ON DELETE RESTRICT,

    CONSTRAINT fk_historial_usuario_app
        FOREIGN KEY (id_usuario_app)
        REFERENCES public.usuarios(id_usuario)
        ON DELETE RESTRICT,

    CONSTRAINT chk_historial_precio_mensual
        CHECK (costo_mensual >= 0),

    CONSTRAINT chk_historial_precio_anual
        CHECK (costo_anualidad >= 0)
);

-- =========================================
-- 3. CAPTURA INICIAL DE PRECIOS
-- =========================================

INSERT INTO public.membresias_precios_historial
(
    id_membresia,
    costo_mensual,
    costo_anualidad,
    id_usuario_app,
    origen
)
SELECT
    m.id_membresia,
    m.costo_mensual,
    m.costo_anualidad,
    NULL,
    'CapturaInicial'
FROM public.membresias m
WHERE NOT EXISTS (
    SELECT 1
    FROM public.membresias_precios_historial h
    WHERE h.id_membresia = m.id_membresia
);

-- =========================================
-- 4. FUNCION DE AUDITORIA
-- =========================================

CREATE OR REPLACE FUNCTION
public.fn_historial_precio_membresia()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
DECLARE
    v_usuario INTEGER;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF NEW.costo_mensual
               IS NOT DISTINCT FROM OLD.costo_mensual
           AND NEW.costo_anualidad
               IS NOT DISTINCT FROM OLD.costo_anualidad
        THEN
            RETURN NEW;
        END IF;
    END IF;

    v_usuario := NULLIF(
        current_setting(
            'gymflow.usuario_actual',
            TRUE
        ),
        ''
    )::INTEGER;

    IF v_usuario IS NULL THEN
        RAISE EXCEPTION
            'Se requiere el usuario administrador para registrar precios';
    END IF;

    PERFORM 1
    FROM public.usuarios u
    JOIN public.roles r
        ON r.id_rol = u.id_rol
    WHERE u.id_usuario = v_usuario
      AND u.estatus = 'Activo'
      AND r.nombre = 'Administrador'
    FOR SHARE OF u, r;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'El usuario no es un administrador activo';
    END IF;

    INSERT INTO public.membresias_precios_historial
    (
        id_membresia,
        costo_mensual,
        costo_anualidad,
        id_usuario_app,
        origen
    )
    VALUES
    (
        NEW.id_membresia,
        NEW.costo_mensual,
        NEW.costo_anualidad,
        v_usuario,
        CASE
            WHEN TG_OP = 'INSERT'
                THEN 'Creacion'
            ELSE 'CambioPrecio'
        END
    );

    RETURN NEW;
END;
$function$;

-- =========================================
-- 5. TRIGGER
-- =========================================

DROP TRIGGER IF EXISTS
    trg_historial_precio_membresia
ON public.membresias;

CREATE TRIGGER trg_historial_precio_membresia
AFTER INSERT OR UPDATE
ON public.membresias
FOR EACH ROW
EXECUTE FUNCTION
    public.fn_historial_precio_membresia();

-- =========================================
-- 6. ALTA DE CLIENTES - VERSION COMPLETA
-- =========================================

CREATE OR REPLACE PROCEDURE
public.sp_alta_cliente(
    IN p_correo VARCHAR,
    IN p_contrasena_hash VARCHAR,
    IN p_id_asistencia VARCHAR,
    IN p_nombre_completo VARCHAR,
    IN p_telefono VARCHAR,
    IN p_id_membresia INTEGER,
    IN p_costo_mensual NUMERIC,
    IN p_costo_anual NUMERIC
)
LANGUAGE plpgsql
AS $procedure$
DECLARE
    v_id_usuario INTEGER;
    v_mensual NUMERIC(10,2);
    v_anual NUMERIC(10,2);
    v_activo BOOLEAN;
BEGIN
    SELECT
        costo_mensual,
        costo_anualidad,
        activo
    INTO
        v_mensual,
        v_anual,
        v_activo
    FROM public.membresias
    WHERE id_membresia = p_id_membresia
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La membresía no existe';
    END IF;

    IF NOT v_activo THEN
        RAISE EXCEPTION 'La membresía está inactiva';
    END IF;

    INSERT INTO public.usuarios
    (
        correo,
        contrasena_hash,
        id_rol
    )
    VALUES
    (
        p_correo,
        p_contrasena_hash,
        4
    )
    RETURNING id_usuario INTO v_id_usuario;

    INSERT INTO public.clientes
    (
        id_usuario,
        id_asistencia,
        nombre_completo,
        telefono,
        id_membresia,
        costo_mensual_acordado,
        costo_anual_acordado
    )
    VALUES
    (
        v_id_usuario,
        p_id_asistencia,
        p_nombre_completo,
        p_telefono,
        p_id_membresia,
        v_mensual,
        v_anual
    );
END;
$procedure$;

-- =========================================
-- 7. ALTA DE CLIENTES - VERSION COMPATIBLE
-- =========================================

CREATE OR REPLACE PROCEDURE
public.sp_alta_cliente(
    IN p_correo VARCHAR,
    IN p_contrasena_hash VARCHAR,
    IN p_nombre_completo VARCHAR,
    IN p_telefono VARCHAR,
    IN p_id_membresia INTEGER,
    IN p_costo_mensual NUMERIC,
    IN p_costo_anual NUMERIC
)
LANGUAGE plpgsql
AS $procedure$
BEGIN
    CALL public.sp_alta_cliente(
        p_correo,
        p_contrasena_hash,
        NULL::VARCHAR,
        p_nombre_completo,
        p_telefono,
        p_id_membresia,
        p_costo_mensual,
        p_costo_anual
    );
END;
$procedure$;

-- =========================================
-- 8. REGISTRO DE PAGOS CON TARIFA OFICIAL
-- =========================================

CREATE OR REPLACE PROCEDURE
public.sp_registrar_pago(
    IN p_id_cliente INTEGER,
    IN p_id_recepcionista INTEGER,
    IN p_monto NUMERIC,
    IN p_tipo VARCHAR
)
LANGUAGE plpgsql
AS $procedure$
DECLARE
    v_id_membresia INTEGER;
    v_tarifa NUMERIC(10,2);
    v_activo BOOLEAN;
    v_referencia_renovacion INTEGER;
BEGIN
    IF p_tipo IS NULL
       OR p_tipo NOT IN ('Mensualidad', 'Anualidad')
    THEN
        RAISE EXCEPTION 'Tipo de pago inválido';
    END IF;

    SELECT id_membresia
    INTO v_id_membresia
    FROM public.clientes
    WHERE id_cliente = p_id_cliente
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El cliente no existe';
    END IF;

    SELECT
        CASE
            WHEN p_tipo = 'Mensualidad'
                THEN costo_mensual
            ELSE costo_anualidad
        END,
        activo
    INTO v_tarifa, v_activo
    FROM public.membresias
    WHERE id_membresia = v_id_membresia
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La membresía no existe';
    END IF;

    IF NOT v_activo THEN
        RAISE EXCEPTION 'La membresía está inactiva';
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

    INSERT INTO public.historial_pagos
    (
        id_cliente,
        id_recepcionista,
        monto_pagado,
        tipo_pago,
        concepto,
        referencia_renovacion
    )
    VALUES
    (
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
$procedure$;

COMMIT;
