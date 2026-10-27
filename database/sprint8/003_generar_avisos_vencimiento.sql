-- Sprint 8: generar avisos internos sin duplicados.

BEGIN;

CREATE OR REPLACE FUNCTION public.fn_generar_avisos_vencimiento(
    p_dias INTEGER DEFAULT 7
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_insertadas BIGINT;
BEGIN
    INSERT INTO public.notificaciones (
        id_usuario,
        tipo,
        titulo,
        mensaje,
        fecha_vencimiento
    )
    SELECT
        c.id_usuario,
        'MembresiaPorVencer',
        'Tu membresía está próxima a vencer',
        FORMAT(
            'Tu membresía vence el %s. Consulta en recepción para renovarla.',
            TO_CHAR(c.fecha_vencimiento, 'YYYY-MM-DD')
        ),
        c.fecha_vencimiento
    FROM public.fn_membresias_por_vencer(p_dias) c
    ON CONFLICT ON CONSTRAINT uq_notificacion_vencimiento
    DO NOTHING;

    GET DIAGNOSTICS v_insertadas = ROW_COUNT;

    RETURN v_insertadas;
END;
$$;

COMMIT;