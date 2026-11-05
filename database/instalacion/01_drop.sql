-- =====================================================
-- GYMFLOW - 01_DROP.SQL
-- Elimina los objetos del esquema public.
-- ADVERTENCIA: Borra todos los datos del esquema.
-- Ejecutar exclusivamente en una base desechable.
-- =====================================================

BEGIN;

DROP SCHEMA IF EXISTS public CASCADE;

CREATE SCHEMA public;

COMMIT;
