-- Sprint 7: cantidad total de pagos registrados de clientes.
-- No incluye pagos de nómina.

BEGIN;

CREATE OR REPLACE VIEW public.vw_admin_pagos_registrados AS
SELECT COUNT(*) AS pagos_registrados
FROM public.historial_pagos;

COMMIT;