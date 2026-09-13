-- =========================================
-- SPRINT 4 - INDICES DE ASISTENCIAS Y PAGOS
-- =========================================

CREATE INDEX IF NOT EXISTS idx_asistencias_id_cliente
ON asistencias(id_cliente);

CREATE INDEX IF NOT EXISTS idx_historial_pagos_id_cliente
ON historial_pagos(id_cliente);