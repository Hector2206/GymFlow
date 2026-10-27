-- Sprint 7: total de expedientes de clientes.
-- Incluye clientes activos e inactivos.

BEGIN;

CREATE OR REPLACE VIEW public.vw_admin_total_clientes AS
SELECT COUNT(*) AS total_clientes
FROM public.clientes;

COMMIT;