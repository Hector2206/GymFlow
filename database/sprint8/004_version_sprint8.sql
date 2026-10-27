-- Sprint 8: versión SQL 1.0.6.
-- Requiere los scripts 001–003 aplicados.

BEGIN;

DO $$
BEGIN
    IF to_regclass('public.notificaciones') IS NULL
       OR to_regprocedure(
           'public.fn_membresias_por_vencer(integer)'
       ) IS NULL
       OR to_regprocedure(
           'public.fn_generar_avisos_vencimiento(integer)'
       ) IS NULL
    THEN
        RAISE EXCEPTION
            'Faltan objetos SQL del Sprint 8. Aplicar scripts 001–003.';
    END IF;
END;
$$;

INSERT INTO public.system_versions (version, updated_at)
SELECT '1.0.6', CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1
    FROM public.system_versions
    WHERE version = '1.0.6'
);

COMMIT;