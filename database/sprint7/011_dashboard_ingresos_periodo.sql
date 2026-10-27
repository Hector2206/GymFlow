-- Sprint 7: ingresos por pagos de clientes.
-- Ambas fechas del periodo son inclusivas.

BEGIN;

CREATE OR REPLACE FUNCTION public.fn_admin_ingresos_periodo(
    p_desde DATE,
    p_hasta DATE
)
RETURNS NUMERIC
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    IF p_desde IS NULL OR p_hasta IS NULL THEN
        RAISE EXCEPTION 'Las fechas del periodo son obligatorias.'
            USING ERRCODE = '22023';
    END IF;

    IF p_hasta < p_desde THEN
        RAISE EXCEPTION 'La fecha final no puede ser anterior a la inicial.'
            USING ERRCODE = '22023';
    END IF;

    RETURN (
        SELECT COALESCE(SUM(h.monto_pagado), 0)
        FROM public.historial_pagos h
        WHERE h.fecha_transaccion >= p_desde::timestamp
          AND h.fecha_transaccion < (
              p_hasta::timestamp + INTERVAL '1 day'
          )
    );
END;
$$;

COMMIT;