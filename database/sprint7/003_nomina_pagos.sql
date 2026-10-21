
-- =============================================
-- GymFlow - Sprint 7
-- 003_nomina_pagos.sql
-- Registro manual de pagos de nómina
-- =============================================

BEGIN;

CREATE TABLE IF NOT EXISTS public.personal_nomina_pagos (
    id_pago BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    id_personal INTEGER NOT NULL
        REFERENCES public.personal(id_personal)
        ON DELETE RESTRICT,

    id_salario BIGINT NOT NULL
        REFERENCES public.personal_salarios_historial(id_salario)
        ON DELETE RESTRICT,

    periodo_inicio DATE NOT NULL,
    periodo_fin DATE NOT NULL,

    monto NUMERIC(12,2) NOT NULL
        CHECK (monto > 0),

    fecha_pago DATE NOT NULL,

    metodo VARCHAR(20) NOT NULL
        CHECK (metodo IN ('Efectivo', 'Transferencia')),

    referencia VARCHAR(100),
    observaciones TEXT,

    estado VARCHAR(15) NOT NULL DEFAULT 'Pagado'
        CHECK (estado IN ('Pagado', 'Cancelado')),

    registrado_por INTEGER NOT NULL
        REFERENCES public.usuarios(id_usuario),

    cancelado_por INTEGER
        REFERENCES public.usuarios(id_usuario),

    fecha_cancelacion TIMESTAMPTZ,
    motivo_cancelacion TEXT,

    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_nomina_periodo
        CHECK (periodo_fin >= periodo_inicio),

    CONSTRAINT chk_nomina_cancelacion
        CHECK (
            estado <> 'Cancelado'
            OR (
                cancelado_por IS NOT NULL
                AND fecha_cancelacion IS NOT NULL
                AND NULLIF(TRIM(motivo_cancelacion), '') IS NOT NULL
            )
        )
);

-- Evitar pagos duplicados del mismo periodo.
CREATE UNIQUE INDEX IF NOT EXISTS ux_nomina_periodo_pagado
ON public.personal_nomina_pagos (
    id_personal,
    periodo_inicio,
    periodo_fin
)
WHERE estado = 'Pagado';

CREATE INDEX IF NOT EXISTS ix_nomina_fecha
ON public.personal_nomina_pagos(fecha_pago);

COMMIT;
