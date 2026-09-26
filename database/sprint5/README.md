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

## Tabla rutinas

Columnas definidas:

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_rutina | SERIAL | PRIMARY KEY | Identificador único de la rutina |
| nombre | VARCHAR(120) | NOT NULL | Nombre de la rutina |
| descripcion | VARCHAR(500) | NULL | Descripción general de la rutina |
| id_cliente | INTEGER | NOT NULL, FOREIGN KEY | Cliente al que pertenece la rutina |

La rutina se relaciona directamente con un cliente mediante `id_cliente`.

El entrenador no se guarda directamente en la rutina, porque el cliente ya tiene la relación `id_entrenador`.

Sprint 5: administración y consulta de rutinas.
