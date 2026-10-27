-- Sprint 7: registros de acceso aprobados del día.
-- Fecha de referencia: CURRENT_DATE de PostgreSQL.

BEGIN;

CREATE OR REPLACE VIEW public.vw_admin_asistencias_dia AS
SELECT COUNT(*) AS asistencias_dia
FROM public.asistencias
WHERE estado_acceso = 'Aprobado'
  AND fecha_hora >= CURRENT_DATE::timestamp
  AND fecha_hora < (CURRENT_DATE + 1)::timestamp;

COMMIT;