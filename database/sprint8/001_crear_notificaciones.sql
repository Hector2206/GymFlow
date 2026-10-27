-- Sprint 8: notificaciones internas de vencimiento.

BEGIN;

CREATE TABLE public.notificaciones (
    id_notificacion BIGINT GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    id_usuario INTEGER NOT NULL
        REFERENCES public.usuarios(id_usuario)
        ON DELETE RESTRICT,

    tipo VARCHAR(40) NOT NULL
        DEFAULT 'MembresiaPorVencer',

    titulo VARCHAR(150) NOT NULL,
    mensaje TEXT NOT NULL,
    fecha_vencimiento DATE NOT NULL,

    leida BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_lectura TIMESTAMPTZ,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_notificacion_tipo
        CHECK (tipo = 'MembresiaPorVencer'),

    CONSTRAINT chk_notificacion_titulo
        CHECK (NULLIF(TRIM(titulo), '') IS NOT NULL),

    CONSTRAINT chk_notificacion_mensaje
        CHECK (NULLIF(TRIM(mensaje), '') IS NOT NULL),

    CONSTRAINT chk_notificacion_lectura
        CHECK (
            (leida = FALSE AND fecha_lectura IS NULL)
            OR
            (leida = TRUE AND fecha_lectura IS NOT NULL)
        ),

    CONSTRAINT uq_notificacion_vencimiento
        UNIQUE (id_usuario, tipo, fecha_vencimiento)
);

CREATE INDEX idx_notificaciones_usuario_recientes
ON public.notificaciones (
    id_usuario,
    creado_en DESC,
    id_notificacion DESC
);

CREATE INDEX idx_notificaciones_usuario_no_leidas
ON public.notificaciones (id_usuario)
WHERE leida = FALSE;

COMMIT;