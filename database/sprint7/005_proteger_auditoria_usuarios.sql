
-- GymFlow - Sprint 7
-- Proteger hashes de contraseñas en auditoría

BEGIN;

CREATE OR REPLACE FUNCTION public.fn_registrar_auditoria()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_usuario INTEGER;
    v_anterior JSONB;
    v_nuevo JSONB;
BEGIN
    v_id_usuario := NULLIF(
        current_setting('gymflow.usuario_actual', true),
        ''
    )::INTEGER;

    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        v_anterior := to_jsonb(OLD);
    END IF;

    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        v_nuevo := to_jsonb(NEW);
    END IF;

    -- Nunca almacenar hashes ni identificadores Google
    IF TG_TABLE_NAME = 'usuarios' THEN
        v_anterior := v_anterior
            - 'contrasena_hash' - 'google_id';

        v_nuevo := v_nuevo
            - 'contrasena_hash' - 'google_id';
    END IF;

    INSERT INTO public.bitacora_auditoria (
        id_usuario_app,
        tabla_afectada,
        accion_realizada,
        datos_viejos,
        datos_nuevos
    )
    VALUES (
        v_id_usuario,
        TG_TABLE_NAME,
        TG_OP,
        v_anterior,
        v_nuevo
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$;

COMMIT;
