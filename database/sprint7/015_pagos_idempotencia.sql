-- GymFlow Sprint 7
-- Protección contra pagos duplicados.
-- No modifica registros históricos.

BEGIN;

CREATE TABLE IF NOT EXISTS public.pagos_idempotencia
(
    clave_idempotencia UUID PRIMARY KEY,

    id_cliente INTEGER NOT NULL,

    tipo_pago VARCHAR(20) NOT NULL,

    id_pago INTEGER UNIQUE,

    fecha_creacion TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_idempotencia_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES public.clientes(id_cliente)
        ON DELETE RESTRICT,

    CONSTRAINT fk_idempotencia_pago
        FOREIGN KEY (id_pago)
        REFERENCES public.historial_pagos(id_pago)
        ON DELETE RESTRICT,

    CONSTRAINT chk_idempotencia_tipo
        CHECK (
            tipo_pago IN ('Mensualidad', 'Anualidad')
        )
);

COMMIT;