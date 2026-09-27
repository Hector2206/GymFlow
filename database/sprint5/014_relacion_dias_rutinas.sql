ALTER TABLE dias_rutina
ADD CONSTRAINT fk_dias_rutina_rutina
FOREIGN KEY (id_rutina)
REFERENCES rutinas (id_rutina)
ON DELETE CASCADE;
