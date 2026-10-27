-- Sprint 7: clientes activos con membresía vigente.
-- La fecha de referencia es CURRENT_DATE de PostgreSQL.

BEGIN;

CREATE OR REPLACE VIEW public.vw_admin_membresias_activas AS
SELECT COUNT(*) AS membresias_activas
FROM public.clientes c
JOIN public.usuarios u
    ON u.id_usuario = c.id_usuario
WHERE u.estatus = 'Activo'
  AND (
      (c.fecha_pago_mensual + INTERVAL '1 month')::date
          >= CURRENT_DATE
      OR
      (c.fecha_pago_anualidad + INTERVAL '1 year')::date
          >= CURRENT_DATE
  );

COMMIT;
