-- Sprint 7: datos para búsqueda y filtros de clientes.

BEGIN;

CREATE OR REPLACE VIEW public.vw_admin_clientes AS
WITH datos AS (
    SELECT
        c.id_cliente,
        c.nombre_completo,
        u.correo,
        c.telefono,
        c.id_membresia,
        m.nombre_plan,
        u.estatus,
        GREATEST(
            (c.fecha_pago_mensual + INTERVAL '1 month')::date,
            (c.fecha_pago_anualidad + INTERVAL '1 year')::date
        ) AS fecha_vencimiento
    FROM public.clientes c
    JOIN public.usuarios u
        ON u.id_usuario = c.id_usuario
    JOIN public.membresias m
        ON m.id_membresia = c.id_membresia
)
SELECT
    id_cliente,
    nombre_completo,
    correo,
    telefono,
    id_membresia,
    nombre_plan,
    estatus,
    CASE
        WHEN fecha_vencimiento IS NULL THEN 'SinPagos'
        WHEN fecha_vencimiento >= CURRENT_DATE THEN 'Vigente'
        ELSE 'Vencida'
    END AS vigencia,
    fecha_vencimiento
FROM datos;

COMMIT;