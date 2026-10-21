-- =============================================
-- GymFlow - Sprint 7
-- 001_ampliar_personal.sql
-- Ampliación segura de la tabla personal
-- =============================================

BEGIN;

ALTER TABLE public.personal
    ADD COLUMN IF NOT EXISTS fecha_baja DATE,
    ADD COLUMN IF NOT EXISTS motivo_baja TEXT,
    ADD COLUMN IF NOT EXISTS fecha_actualizacion
        TIMESTAMPTZ NOT NULL DEFAULT NOW();


-- Evitar fechas de baja anteriores al alta.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'public.personal'::regclass
          AND conname = 'chk_personal_fecha_baja'
    ) THEN
        ALTER TABLE public.personal
        ADD CONSTRAINT chk_personal_fecha_baja
        CHECK (
            fecha_baja IS NULL
            OR fecha_baja >= fecha_alta
        );
    END IF;
END $$;


COMMIT;
