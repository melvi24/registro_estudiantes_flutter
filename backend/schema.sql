-- Crear base de datos si no existe
CREATE DATABASE IF NOT EXISTS student_db;
USE student_db;

-- Tabla para almacenar estudiantes
CREATE TABLE students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    age INT NOT NULL CHECK (age > 0), -- Asegura que la edad sea positiva
    address VARCHAR(150) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Registro de creación
);




