
-- =============================================
-- GymFlow - Sprint 7
-- 004_migrar_salarios_existentes.sql
-- Migración de salarios mensuales existentes
-- =============================================

BEGIN;

INSERT INTO public.personal_salarios_historial (
    id_personal,
    monto,
    periodicidad,
    vigente_desde,
    vigente_hasta,
    motivo,
    registrado_por
)
SELECT
    p.id_personal,
    p.salario,
    'Mensual',
    p.fecha_alta,
    NULL,
    'Migración de sueldo inicial - Sprint 7',
    NULL
FROM public.personal p
WHERE NOT EXISTS (
    SELECT 1
    FROM public.personal_salarios_historial h
    WHERE h.id_personal = p.id_personal
);

COMMIT;
