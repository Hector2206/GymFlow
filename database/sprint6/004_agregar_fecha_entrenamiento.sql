-- ============================================
-- GYMFLOW - SPRINT 6
-- Fecha de entrenamiento en progreso
-- ============================================

BEGIN;

ALTER TABLE progreso
ADD COLUMN IF NOT EXISTS fecha_entrenamiento DATE;

UPDATE progreso
SET fecha_entrenamiento = fecha_registro::DATE
WHERE fecha_entrenamiento IS NULL;

ALTER TABLE progreso
ALTER COLUMN fecha_entrenamiento SET DEFAULT CURRENT_DATE;

ALTER TABLE progreso
ALTER COLUMN fecha_entrenamiento SET NOT NULL;

COMMIT;