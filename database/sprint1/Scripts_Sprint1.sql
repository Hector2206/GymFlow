 
 --cREACION DE LA TABLA DE VERSIONES PARA PRUEBA DE CONEXION LA API-WEB-APP
 CREATE TABLE system_versions (
    id SERIAL PRIMARY KEY,
    version VARCHAR(20) NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO system_versions (version)
VALUES ('1.0.0');

SELECT * FROM system_versions;

UPDATE system_versions
SET version = '1.0.1',
    updated_at = CURRENT_TIMESTAMP
WHERE id = 1;