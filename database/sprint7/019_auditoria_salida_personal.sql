
BEGIN;

ALTER TABLE public.personal_asistencias
    ADD COLUMN IF NOT EXISTS salida_registrada_por INTEGER;

ALTER TABLE public.personal_asistencias
    ADD COLUMN IF NOT EXISTS fecha_registro_salida TIMESTAMPTZ;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_personal_asistencias_salida_usuario'
          AND conrelid = 'public.personal_asistencias'::regclass
    ) THEN
        ALTER TABLE public.personal_asistencias
            ADD CONSTRAINT fk_personal_asistencias_salida_usuario
            FOREIGN KEY (salida_registrada_por)
            REFERENCES public.usuarios(id_usuario)
            ON DELETE RESTRICT;
    END IF;
END $$;

COMMIT;
