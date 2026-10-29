
BEGIN;

CREATE TABLE IF NOT EXISTS public.personal_asistencias (
    id_asistencia_personal BIGSERIAL PRIMARY KEY,

    id_personal INTEGER NOT NULL
        REFERENCES public.personal(id_personal)
        ON DELETE RESTRICT,

    fecha DATE NOT NULL,

    hora_entrada TIME NOT NULL,
    hora_salida TIME NULL,

    registrado_por INTEGER NOT NULL
        REFERENCES public.usuarios(id_usuario)
        ON DELETE RESTRICT,

    fecha_registro TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_asistencia_horario
        CHECK (
            hora_salida IS NULL
            OR hora_salida >= hora_entrada
        ),

    CONSTRAINT uq_asistencia_personal_fecha
        UNIQUE (id_personal, fecha)
);

CREATE INDEX IF NOT EXISTS idx_personal_asistencias_fecha
    ON public.personal_asistencias(fecha);

CREATE INDEX IF NOT EXISTS idx_personal_asistencias_personal
    ON public.personal_asistencias(id_personal, fecha DESC);

COMMIT;
