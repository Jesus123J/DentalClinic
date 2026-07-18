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

CREATE INDEX idx_appointments_date ON appointments(date_time);
CREATE INDEX idx_clinical_records_patient ON clinical_records(patient_id, record_date);
