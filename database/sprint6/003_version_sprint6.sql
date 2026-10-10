
-- ============================================
-- GYMFLOW - SPRINT 6
-- Archivo: 003_version_sprint6.sql
-- Version del sistema: 1.0.4
-- ============================================

INSERT INTO system_versions (
    version,
    updated_at
)
SELECT
    '1.0.4',
    CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1
    FROM system_versions
    WHERE version = '1.0.4'
);

