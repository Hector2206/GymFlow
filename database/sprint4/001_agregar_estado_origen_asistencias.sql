ALTER TABLE asistencias
ADD COLUMN estado_acceso VARCHAR(20) NOT NULL DEFAULT 'Aprobado';

ALTER TABLE asistencias
ADD COLUMN origen_registro VARCHAR(30) NOT NULL DEFAULT 'LectorCodigo';

ALTER TABLE asistencias
ADD CONSTRAINT asistencias_estado_acceso_check
CHECK (estado_acceso IN ('Aprobado', 'Rechazado'));