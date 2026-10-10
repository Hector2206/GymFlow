
-- ============================================
-- GYMFLOW - SPRINT 6
-- Archivo: 002_indices_progreso.sql
-- Indices para consultas de progreso
-- ============================================

-- Optimizar consultas por cliente
CREATE INDEX IF NOT EXISTS idx_progreso_cliente
ON progreso (id_cliente);

-- Optimizar consultas por ejercicio
CREATE INDEX IF NOT EXISTS idx_progreso_ejercicio
ON progreso (id_ejercicio);

-- Optimizar historial de un cliente
-- por ejercicio y fecha
CREATE INDEX IF NOT EXISTS idx_progreso_cliente_ejercicio_fecha
ON progreso (
    id_cliente,
    id_ejercicio,
    fecha_registro DESC
);
