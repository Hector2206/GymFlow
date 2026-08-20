--Tablas especificadas para entregar en el sprint 2
CREATE TABLE roles (
    id INT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    rol_id INT NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_rol FOREIGN KEY (rol_id) REFERENCES roles (id) ON DELETE RESTRICT
);

CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    usuario_id UUID NOT NULL UNIQUE,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    fecha_nacimiento DATE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuario_cliente FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE
);

CREATE TABLE membresias (
    id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL,
    tipo VARCHAR(50) NOT NULL, 
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado VARCHAR(20) DEFAULT 'Activa',
    CONSTRAINT fk_cliente_membresia FOREIGN KEY (cliente_id) REFERENCES clientes (id) ON DELETE CASCADE
);

CREATE TABLE pagos (
    id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    fecha_pago TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    concepto VARCHAR(100) NOT NULL,
    CONSTRAINT fk_cliente_pago FOREIGN KEY (cliente_id) REFERENCES clientes (id) ON DELETE CASCADE
);

CREATE TABLE asistencias (
    id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL,
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cliente_asistencia FOREIGN KEY (cliente_id) REFERENCES clientes (id) ON DELETE CASCADE
);

--Agregar los datos para utilizar en las tablas 

-- Insertar roles
INSERT INTO roles (id, nombre) VALUES 
(1, 'Administrador'), 
(2, 'Recepcionista'), 
(3, 'Cliente');

-- Insertar Usuarios de Prueba 

INSERT INTO usuarios (id, email, password_hash, rol_id) VALUES
('preuba no datos reales', 'prueba no datos reales', 'prueba', 1),
('preuba no datos reales', 'prueba no datos reales', 'prueba', 2),
('preuba no datos reales', 'prueba no datos reales', 'prueba', 3);

-- Insertar Perfiles
INSERT INTO clientes (usuario_id, nombres, apellidos, telefono, fecha_nacimiento) VALUES
('preuba no datos reales', 'prueba no datos reales', 'prueba', 1),
('preuba no datos reales', 'prueba no datos reales', 'prueba', 1),
('preuba no datos reales', 'prueba no datos reales', 'prueba', 1);

-- Pruebas
INSERT INTO membresias (cliente_id, tipo, fecha_inicio, fecha_fin) VALUES 
(3, 'Mensual', CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days');

INSERT INTO pagos (cliente_id, monto, concepto) VALUES 
(3, 499.00, 'Pago Mensualidad Agosto');