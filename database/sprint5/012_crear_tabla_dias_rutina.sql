CREATE TABLE dias_rutina
(
    id_dia SERIAL
        PRIMARY KEY,
    dia VARCHAR(20) NOT NULL
);

ALTER TABLE dias_rutina
    OWNER TO gymflow_app;
