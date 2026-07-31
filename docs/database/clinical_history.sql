-- Historia clinica odontologica formal (formato peruano, 8 secciones).
-- Es UNA por paciente y se complementa con clinical_records, que son las
-- evoluciones/atenciones puntuales (seccion VIII: control y evolucion).
USE dental_clinic;

CREATE TABLE IF NOT EXISTS clinical_histories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL UNIQUE,
  hc_number VARCHAR(30),                 -- N° de historia clinica
  opened_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- ---------- I. ANAMNESIS ----------
  -- Filiacion (lo basico ya vive en patients; aqui lo especifico del formato)
  birth_place VARCHAR(150),              -- lugar de nacimiento
  origin VARCHAR(150),                   -- procedencia
  occupation VARCHAR(120),
  trips_last_year VARCHAR(200),
  emergency_contact VARCHAR(200),

  chief_complaint TEXT,                  -- motivo de consulta

  -- Enfermedad actual
  illness_time VARCHAR(100),
  illness_onset VARCHAR(100),            -- inicio
  illness_course VARCHAR(100),           -- curso
  illness_signs TEXT,                    -- signos y sintomas principales
  illness_story TEXT,                    -- relato

  -- Funciones biologicas (apetito, sed, sueno, sudor, peso, orina, etc.)
  biological_functions JSON,
  risks TEXT,

  -- Antecedentes personales generales y fisiologicos
  personal_general JSON,                 -- residencias, vivienda, alimentacion...
  personal_physiological JSON,           -- parto, desarrollo, gineco-obstetricos

  -- Antecedentes patologicos (los relevantes se consultan y alertan)
  path_hypertension TINYINT(1) DEFAULT 0,
  path_cardiovascular TINYINT(1) DEFAULT 0,
  path_diabetes TINYINT(1) DEFAULT 0,
  path_endocrine TINYINT(1) DEFAULT 0,
  path_asthma TINYINT(1) DEFAULT 0,
  path_hepatitis TINYINT(1) DEFAULT 0,
  path_liver TINYINT(1) DEFAULT 0,
  path_kidney TINYINT(1) DEFAULT 0,
  path_tbc TINYINT(1) DEFAULT 0,
  path_infectious TINYINT(1) DEFAULT 0,
  path_bleeding TINYINT(1) DEFAULT 0,    -- enfermedad hemorragica
  path_other TINYINT(1) DEFAULT 0,
  path_medication TINYINT(1) DEFAULT 0,  -- ingesta de medicamentos
  allergy_drugs TINYINT(1) DEFAULT 0,
  allergy_food TINYINT(1) DEFAULT 0,
  allergy_detail VARCHAR(300),
  previous_surgeries TINYINT(1) DEFAULT 0,
  previous_hospitalizations TINYINT(1) DEFAULT 0,
  habit_tobacco TINYINT(1) DEFAULT 0,
  habit_alcohol TINYINT(1) DEFAULT 0,
  habit_drugs TINYINT(1) DEFAULT 0,
  is_pregnant TINYINT(1) DEFAULT 0,
  pregnancy_month VARCHAR(10),
  pathological_notes TEXT,               -- ampliacion

  -- Antecedentes estomatologicos
  last_dental_visit VARCHAR(120),
  previous_dental_treatments TEXT,
  previous_anesthesia TINYINT(1) DEFAULT 0,
  anesthesia_reaction TINYINT(1) DEFAULT 0,
  anesthesia_reaction_detail VARCHAR(300),
  previous_extractions TINYINT(1) DEFAULT 0,
  extraction_complications TINYINT(1) DEFAULT 0,
  extraction_complication_detail VARCHAR(300),
  stomatological_notes TEXT,

  family_history TEXT,                   -- antecedentes familiares
  rasa JSON,                             -- revision por sistemas y aparatos

  -- ---------- II. EXAMEN CLINICO ----------
  ectoscopy TEXT,
  vital_blood_pressure VARCHAR(20),
  vital_pulse VARCHAR(20),
  vital_heart_rate VARCHAR(20),
  vital_respiratory_rate VARCHAR(20),
  vital_temperature VARCHAR(20),
  general_exam JSON,                     -- piel, TCS, oseomioarticular, linfatico
  extraoral_exam JSON,                   -- craneo, cara, ojos, ATM, cuello...
  intraoral_exam JSON,                   -- labios, mucosa, lengua, encias...
  lesion_map TEXT,                       -- mapeo anatomico de lesiones

  -- ---------- III a VII ----------
  presumptive_diagnosis TEXT,
  diagnostic_plan TEXT,
  auxiliary_exams TEXT,
  definitive_diagnosis TEXT,
  treatment_plan TEXT,
  performed_treatments TEXT,

  -- Responsable
  dentist_name VARCHAR(150),
  dentist_cop VARCHAR(30),               -- N° de colegiatura

  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(120),
  CONSTRAINT fk_history_patient FOREIGN KEY (patient_id)
    REFERENCES patients(id) ON DELETE CASCADE
) CHARACTER SET utf8mb4;
