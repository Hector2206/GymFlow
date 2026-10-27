-- Sprint 7: índices para búsqueda parcial por nombre y correo.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_clientes_nombre_trgm
ON public.clientes
USING GIN (nombre_completo gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_usuarios_correo_trgm
ON public.usuarios
USING GIN (correo gin_trgm_ops);

COMMIT;