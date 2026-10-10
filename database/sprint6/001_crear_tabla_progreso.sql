
-- ============================================
-- GYMFLOW - SPRINT 6
-- Archivo: 001_crear_tabla_progreso.sql
-- Registro del progreso de entrenamiento
-- ============================================

CREATE TABLE IF NOT EXISTS progreso
(
    id_progreso SERIAL PRIMARY KEY,

    id_cliente INTEGER NOT NULL,

    id_ejercicio INTEGER NOT NULL,

    peso_utilizado NUMERIC(10,2) NOT NULL,

    fecha_registro TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_progreso_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente)
        ON DELETE RESTRICT,

    CONSTRAINT fk_progreso_ejercicio
        FOREIGN KEY (id_ejercicio)
        REFERENCES ejercicios(id_ejercicio)
        ON DELETE RESTRICT,

    CONSTRAINT chk_progreso_peso
        CHECK (peso_utilizado > 0)
);
