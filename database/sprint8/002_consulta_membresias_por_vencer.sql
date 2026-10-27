-- Sprint 8: candidatos para avisos de vencimiento.
-- Usa la misma regla de vigencia del Sprint 7.

BEGIN;

CREATE OR REPLACE FUNCTION public.fn_membresias_por_vencer(
    p_dias INTEGER DEFAULT 7
)
RETURNS TABLE (
    id_cliente INTEGER,
    id_usuario INTEGER,
    nombre_completo VARCHAR,
    fecha_vencimiento DATE
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    IF p_dias IS NULL OR p_dias < 0 OR p_dias > 365 THEN
        RAISE EXCEPTION
            'Los días de anticipación deben estar entre 0 y 365.'
            USING ERRCODE = '22023';
    END IF;

    RETURN QUERY
    WITH candidatos AS (
        SELECT
            c.id_cliente,
            c.id_usuario,
            c.nombre_completo,
            GREATEST(
                (c.fecha_pago_mensual + INTERVAL '1 month')::date,
                (c.fecha_pago_anualidad + INTERVAL '1 year')::date
            ) AS vencimiento
        FROM public.clientes c
        JOIN public.usuarios u
            ON u.id_usuario = c.id_usuario
        WHERE u.estatus = 'Activo'
    )
    SELECT
        c.id_cliente,
        c.id_usuario,
        c.nombre_completo,
        c.vencimiento
    FROM candidatos c
    WHERE c.vencimiento BETWEEN CURRENT_DATE
                           AND CURRENT_DATE + p_dias
    ORDER BY c.vencimiento, c.id_cliente;
END;
$$;

COMMIT;