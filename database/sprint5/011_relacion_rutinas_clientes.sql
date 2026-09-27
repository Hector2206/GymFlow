ALTER TABLE rutinas
ADD CONSTRAINT fk_rutina_cliente
FOREIGN KEY (id_cliente)
REFERENCES clientes (id_cliente)
ON DELETE CASCADE;
