
-- =============================================
-- GymFlow - Sprint 7
-- 002_historial_salarios.sql
-- Historial de sueldos de empleados
-- =============================================

BEGIN;

CREATE TABLE IF NOT EXISTS public.personal_salarios_historial (
    id_salario BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    id_personal INTEGER NOT NULL
        REFERENCES public.personal(id_personal)
        ON DELETE RESTRICT,

    monto NUMERIC(12,2) NOT NULL
        CHECK (monto >= 0),

    periodicidad VARCHAR(20) NOT NULL
        CHECK (periodicidad IN (
            'Semanal', 'Quincenal', 'Mensual'
        )),

    vigente_desde DATE NOT NULL,
    vigente_hasta DATE,

    motivo TEXT,

    registrado_por INTEGER
        REFERENCES public.usuarios(id_usuario),

    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_salario_fechas
        CHECK (
            vigente_hasta IS NULL
            OR vigente_hasta >= vigente_desde
        )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_salario_vigente
ON public.personal_salarios_historial(id_personal)
WHERE vigente_hasta IS NULL;

COMMIT;
