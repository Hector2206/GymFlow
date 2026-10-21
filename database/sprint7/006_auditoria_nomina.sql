-- Auditoría de registros y cambios en pagos de nómina.
BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgrelid = 'public.personal_nomina_pagos'::regclass
          AND tgname = 'trg_auditoria_nomina'
          AND NOT tgisinternal
    ) THEN
        CREATE TRIGGER trg_auditoria_nomina
        AFTER INSERT OR UPDATE OR DELETE
        ON public.personal_nomina_pagos
        FOR EACH ROW
        EXECUTE FUNCTION public.fn_registrar_auditoria();
    END IF;
END
$$;

COMMIT;