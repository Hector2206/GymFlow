-- ============================================================
-- GymFlow - Sprint 4
-- Archivo: 006_actualizar_codigo_acceso_y_pagos.sql
-- Objetivo:
--   1) Formalizar codigo_acceso en clientes.
--   2) Mantener codigo_acceso sincronizado con id_asistencia.
--   3) Agregar concepto y referencia de renovacion a historial_pagos.
--   4) Enlazar renovaciones existentes.
--   5) Actualizar sp_registrar_pago para futuras renovaciones.
-- ============================================================

-- ============================================================
-- 1. CODIGO DE ACCESO EN CLIENTES
-- ============================================================

ALTER TABLE clientes
ADD COLUMN IF NOT EXISTS codigo_acceso VARCHAR(20);

-- Copiar los codigos ya existentes.
UPDATE clientes
SET codigo_acceso = id_asistencia
WHERE codigo_acceso IS NULL;

-- Crear restriccion UNIQUE solo si no existe.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'uq_clientes_codigo_acceso'
    ) THEN
        ALTER TABLE clientes
        ADD CONSTRAINT uq_clientes_codigo_acceso
        UNIQUE (codigo_acceso);
    END IF;
END
$$;

-- Indice explicito solicitado en Sprint 4.
CREATE INDEX IF NOT EXISTS idx_clientes_codigo_acceso
ON clientes(codigo_acceso);

-- Mantener sincronizado codigo_acceso para futuros clientes.
CREATE OR REPLACE FUNCTION fn_sync_codigo_acceso()
RETURNS trigger
LANGUAGE plpgsql
AS
$$
BEGIN
    IF NEW.codigo_acceso IS NULL OR NEW.codigo_acceso = '' THEN
        NEW.codigo_acceso := NEW.id_asistencia;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_codigo_acceso ON clientes;

CREATE TRIGGER trg_sync_codigo_acceso
BEFORE INSERT OR UPDATE OF id_asistencia, codigo_acceso
ON clientes
FOR EACH ROW
EXECUTE FUNCTION fn_sync_codigo_acceso();


-- ============================================================
-- 2. CONCEPTO Y REFERENCIA DE RENOVACION EN PAGOS
-- ============================================================

ALTER TABLE historial_pagos
ADD COLUMN IF NOT EXISTS concepto VARCHAR(100);

ALTER TABLE historial_pagos
ADD COLUMN IF NOT EXISTS referencia_renovacion INTEGER;

-- Completar concepto en pagos anteriores.
UPDATE historial_pagos
SET concepto = tipo_pago
WHERE concepto IS NULL;

-- Crear FK de autorreferencia solo si no existe.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_historial_pagos_renovacion'
    ) THEN
        ALTER TABLE historial_pagos
        ADD CONSTRAINT fk_historial_pagos_renovacion
        FOREIGN KEY (referencia_renovacion)
        REFERENCES historial_pagos(id_pago);
    END IF;
END
$$;

-- Enlazar pagos existentes con el pago anterior del mismo cliente y tipo.
WITH pagos_ordenados AS (
    SELECT
        id_pago,
        LAG(id_pago) OVER (
            PARTITION BY id_cliente, tipo_pago
            ORDER BY fecha_transaccion, id_pago
        ) AS pago_anterior
    FROM historial_pagos
)
UPDATE historial_pagos hp
SET referencia_renovacion = po.pago_anterior
FROM pagos_ordenados po
WHERE hp.id_pago = po.id_pago
  AND po.pago_anterior IS NOT NULL
  AND hp.referencia_renovacion IS NULL;


-- ============================================================
-- 3. PROCEDIMIENTO DE REGISTRO DE PAGOS / RENOVACIONES
-- ============================================================

CREATE OR REPLACE PROCEDURE sp_registrar_pago(
    IN p_id_cliente integer,
    IN p_id_recepcionista integer,
    IN p_monto numeric,
    IN p_tipo character varying
)
LANGUAGE plpgsql
AS
$$
DECLARE
    v_referencia_renovacion integer;
BEGIN
    -- Buscar el pago anterior del mismo cliente y mismo tipo.
    SELECT id_pago
    INTO v_referencia_renovacion
    FROM historial_pagos
    WHERE id_cliente = p_id_cliente
      AND tipo_pago = p_tipo
    ORDER BY fecha_transaccion DESC, id_pago DESC
    LIMIT 1;

    -- Registrar el pago.
    INSERT INTO historial_pagos (
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
        p_monto,
        p_tipo,
        p_tipo,
        v_referencia_renovacion
    );

    -- Actualizar vigencia.
    IF p_tipo = 'Mensualidad' THEN

        UPDATE clientes
        SET fecha_pago_mensual =
            CASE
                WHEN fecha_pago_mensual IS NULL
                    THEN CURRENT_DATE

                WHEN fecha_pago_mensual + INTERVAL '1 month' > CURRENT_DATE
                    THEN fecha_pago_mensual + INTERVAL '1 month'

                ELSE CURRENT_DATE
            END
        WHERE id_cliente = p_id_cliente;

    ELSIF p_tipo = 'Anualidad' THEN

        UPDATE clientes
        SET fecha_pago_anualidad =
            CASE
                WHEN fecha_pago_anualidad IS NULL
                    THEN CURRENT_DATE

                WHEN fecha_pago_anualidad + INTERVAL '1 year' > CURRENT_DATE
                    THEN fecha_pago_anualidad + INTERVAL '1 year'

                ELSE CURRENT_DATE
            END
        WHERE id_cliente = p_id_cliente;

    END IF;
END;
$$;


-- ============================================================
-- 4. VERIFICACIONES OPCIONALES
-- ============================================================

-- Codigos de acceso.
SELECT
    id_cliente,
    nombre_completo,
    id_asistencia,
    codigo_acceso
FROM clientes
ORDER BY id_cliente;

-- Indices de codigo_acceso.
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'clientes'
  AND indexdef ILIKE '%codigo_acceso%';

-- Pagos, concepto y referencias de renovacion.
SELECT
    id_pago,
    id_cliente,
    monto_pagado,
    tipo_pago,
    concepto,
    referencia_renovacion,
    fecha_transaccion
FROM historial_pagos
ORDER BY id_pago;
