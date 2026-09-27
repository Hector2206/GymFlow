CREATE VIEW vw_clientes_por_entrenador AS
SELECT
    c.id_entrenador,
    p.nombre_completo AS nombre_entrenador,
    c.id_cliente,
    c.id_usuario,
    c.nombre_completo AS nombre_cliente,
    u.correo,
    c.telefono,
    u.estatus
FROM clientes c
JOIN usuarios u
    ON c.id_usuario = u.id_usuario
JOIN personal p
    ON c.id_entrenador = p.id_personal
WHERE c.id_entrenador IS NOT NULL;

ALTER TABLE vw_clientes_por_entrenador
    OWNER TO gymflow_app;
