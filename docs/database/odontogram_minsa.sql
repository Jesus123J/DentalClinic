-- Odontograma segun NTS N 150-MINSA-2019/DGIESP:
-- registro por pieza Y por cara, con denticion permanente y decidua.
USE dental_clinic;

ALTER TABLE odontogram DROP INDEX uq_patient_tooth;

ALTER TABLE odontogram
  ADD COLUMN surface VARCHAR(12) NOT NULL DEFAULT 'completa' AFTER tooth,
  ADD COLUMN dentition ENUM('permanente','decidua') NOT NULL DEFAULT 'permanente'
    AFTER surface;

ALTER TABLE odontogram
  ADD UNIQUE KEY uq_patient_tooth_surface (patient_id, tooth, surface);

ALTER TABLE odontogram_history
  ADD COLUMN surface VARCHAR(12) NOT NULL DEFAULT 'completa' AFTER tooth;

-- Especificaciones y observaciones del pie del formato oficial
CREATE TABLE IF NOT EXISTS odontogram_notes (
  patient_id INT PRIMARY KEY,
  specifications TEXT,
  observations TEXT,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(120),
  CONSTRAINT fk_odo_notes_patient FOREIGN KEY (patient_id)
    REFERENCES patients(id) ON DELETE CASCADE
) CHARACTER SET utf8mb4;
