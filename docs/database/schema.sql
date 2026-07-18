-- Esquema de base de datos MySQL para el sistema odontologico
CREATE DATABASE IF NOT EXISTS dental_clinic CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE dental_clinic;

CREATE TABLE IF NOT EXISTS patients (
  id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  document_id VARCHAR(20),
  phone VARCHAR(20),
  email VARCHAR(120),
  birth_date DATE NULL,
  allergies TEXT,
  notes TEXT,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS appointments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  date_time DATETIME NOT NULL,
  reason VARCHAR(200),
  status ENUM('pendiente','atendida','cancelada') NOT NULL DEFAULT 'pendiente',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_appointments_patient FOREIGN KEY (patient_id)
    REFERENCES patients(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS clinical_records (
  id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  record_date DATE NOT NULL,
  diagnosis VARCHAR(300) NOT NULL,
  treatment VARCHAR(300),
  observations TEXT,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_clinical_records_patient FOREIGN KEY (patient_id)
    REFERENCES patients(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password_hash CHAR(64) NOT NULL,
  salt VARCHAR(32) NOT NULL,
  full_name VARCHAR(120) NOT NULL,
  role ENUM('admin','odontologo','recepcion') NOT NULL DEFAULT 'recepcion',
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Usuarios iniciales (cambiar las contrasenas en produccion).
-- password_hash = SHA256(salt + contrasena)
-- admin/admin123, recepcion/recepcion123, doctor/doctor123
INSERT IGNORE INTO users (username, password_hash, salt, full_name, role) VALUES
('admin', '965c41d79a8ca21c8656feba892b8ab5d722f8c2d79194b07fca012f199ad6df',
 'f3a9c1d27b5e4816', 'Administrador', 'admin'),
('recepcion', '75b7d2b56d3219184b998067535e26629653dc467f62d20b353ffe62bca0aaf2',
 '9d2e6a1c4f8b3705', 'Rosa Mendoza', 'recepcion'),
('doctor', 'aebbf179945111d3cf6cd4eb119169f06faebe9dc2b9d0fc21c668b0d94d20a8',
 '2b7c9e4a6d1f8350', 'Dr. Juan Perez', 'odontologo');

CREATE INDEX idx_appointments_date ON appointments(date_time);
CREATE INDEX idx_clinical_records_patient ON clinical_records(patient_id, record_date);
