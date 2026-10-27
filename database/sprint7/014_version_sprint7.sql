-- Sprint 7: versión 1.0.5.
-- Ejecutar después de aplicar los scripts 001–013.

BEGIN;

INSERT INTO public.system_versions (
    version,
    updated_at
)
SELECT
    '1.0.5',
    CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1
    FROM public.system_versions
    WHERE version = '1.0.5'
);

COMMIT;