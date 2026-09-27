ALTER TABLE ejercicios_rutina
ADD CONSTRAINT fk_ejercicios_rutina_dia
FOREIGN KEY (id_dia)
REFERENCES dias_rutina (id_dia)
ON DELETE CASCADE;

ALTER TABLE ejercicios_rutina
ADD CONSTRAINT fk_ejercicios_rutina_ejercicio
FOREIGN KEY (id_ejercicio)
REFERENCES ejercicios (id_ejercicio)
ON DELETE RESTRICT;
