# Diccionario de Datos - GymFlow

Este documento define la estructura de la base de datos relacional (PostgreSQL) para GymFlow del sprint 2
---

## 1. Tabla: `roles`
**Proposito:** Niveles de acceso a sistema

| Columna | Tipo de Dato | Llave | Descripcion |
| :--- | :--- | :--- | :--- |
| `id` | INT | PK | Identificador unico del rol |
| `nombre` | VARCHAR(50) | | Nombre del rol |

## 2. Tabla: `usuarios`
**Proposito:** Almacena las credenciales y el estado de acceso de las personas

| Columna | Tipo de Dato | Llave | Descripcion |
| :--- | :--- | :--- | :--- |
| `id` | UUID | PK | Identificador unico universa |
| `email` | VARCHAR(150) | | Correo electronico usado para iniciar sesion |
| `password_hash` | VARCHAR(255) | | Contraseña encriptada|
| `rol_id` | INT | FK | Relacion con la tabla roles |
| `activo` | BOOLEAN | | True = Acceso permitido, False = Cuenta deshabilitada  |
| `fecha_creacion`| TIMESTAMP | | Fecha y hora de registro en el sistema |

## 3. Tabla: `clientes`
**Proposito:** Almacena la informacion personal y de contacto de los usuarios del gimnasio

| Columna | Tipo de Dato | Llave | Descripcion |
| :--- | :--- | :--- | :--- |
| `id` | SERIAL | PK | Identificador interno unico del perfil |
| `usuario_id` | UUID | FK | Relacion 1 a 1 con sus credenciales de acceso |
| `nombres` | VARCHAR(100) | | Nombre(s) de pila. |
| `apellidos` | VARCHAR(100) | | Apellidos del usuario. |
| `telefono` | VARCHAR(20) | | Numero de contacto principal |
| `fecha_nacimiento`| DATE | | Fecha de nacimiento para calcular edad
| `fecha_registro`| TIMESTAMP | | Momento en el que se completo su perfil en el sistema |

## 4. Tabla: `membresias`
**Proposito:** Controla la vigencia y el derecho de acceso al gimnasio de cada cliente

| Columna | Tipo de Dato | Llave | Descripcion |
| :--- | :--- | :--- | :--- |
| `id` | SERIAL | PK | Identificador unico de la membresia |
| `cliente_id` | INT | FK | Relacion con el cliente dueño de la membresia |
| `tipo` | VARCHAR(50) | | Tipo de plan contratado |
| `fecha_inicio` | DATE | | Dia exacto en que inicia la vigencia |
| `fecha_fin` | DATE | | Dia de termino de la vigencia  |
| `estado` | VARCHAR(20) | | Estado de la membresia|

## 5. Tabla: `pagos`
**Proposito:** Registra los ingresos y cobros realizados en el gimnasio

| Columna | Tipo de Dato | Llave | Descripcion |
| :--- | :--- | :--- | :--- |
| `id` | SERIAL | PK | Identificador unico del recibo o comprobante de pago|
| `cliente_id` | INT | FK | Cliente que realizo el desembolso |
| `monto` | DECIMAL(10,2)| | Cantidad economica cobrada |
| `fecha_pago` | TIMESTAMP | | Momento  en el que se registro el cobro en el sistema |
| `concepto` | VARCHAR(100) | | Justificacion o motivo del cobro |

## 6. Tabla: `asistencias`
**Proposito:** Historial de entradas fisicos al gym

| Columna | Tipo de Dato | Llave | Descripcion |
| :--- | :--- | :--- | :--- |
| `id` | SERIAL | PK | Identificador unico de asistencia |
| `cliente_id` | INT | FK | Cliente al que se le concedio el acceso |
| `fecha_hora` | TIMESTAMP | | Momento exacto de lectura o validacion en recepcion |