# Base de datos - Sprint 5

## Tabla ejercicios

Columnas definidas:

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_ejercicio | SERIAL | PRIMARY KEY | Identificador único del ejercicio |
| nombre | VARCHAR(120) | NOT NULL | Nombre del ejercicio |
| descripcion | VARCHAR(500) | NULL | Descripción o indicaciones del ejercicio |
| estado | BOOLEAN | NOT NULL DEFAULT TRUE | Indica si el ejercicio está activo |

La eliminación de ejercicios será lógica mediante el campo `estado`.

Sprint 5: administración de rutinas y ejercicios.
