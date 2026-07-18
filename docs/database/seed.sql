-- Datos de ejemplo para probar el sistema
USE dental_clinic;

INSERT INTO patients (first_name, last_name, document_id, phone, email, birth_date, allergies) VALUES
('Maria', 'Gonzalez Perez', '45871236', '987654321', 'maria.gonzalez@gmail.com', '1990-05-14', 'Penicilina'),
('Carlos', 'Ramirez Soto', '41236587', '912345678', 'carlos.ramirez@gmail.com', '1985-11-02', NULL),
('Lucia', 'Torres Diaz', '47895123', '956781234', 'lucia.torres@gmail.com', '2001-03-27', NULL);

INSERT INTO appointments (patient_id, date_time, reason, status) VALUES
(1, CONCAT(CURDATE(), ' 09:00:00'), 'Limpieza dental', 'pendiente'),
(2, CONCAT(CURDATE(), ' 10:30:00'), 'Dolor en molar inferior', 'pendiente'),
(3, CONCAT(CURDATE(), ' 15:00:00'), 'Control de ortodoncia', 'pendiente'),
(1, DATE_SUB(NOW(), INTERVAL 3 DAY), 'Consulta general', 'atendida'),
(2, DATE_SUB(NOW(), INTERVAL 5 DAY), 'Extraccion', 'atendida');

INSERT INTO clinical_records (patient_id, record_date, diagnosis, treatment, observations) VALUES
(1, DATE_SUB(CURDATE(), INTERVAL 3 DAY), 'Gingivitis leve', 'Limpieza profunda y enjuague con clorhexidina', 'Control en 2 semanas'),
(2, DATE_SUB(CURDATE(), INTERVAL 5 DAY), 'Caries profunda en pieza 3.6', 'Extraccion de la pieza', 'Se receto amoxicilina 500mg por 7 dias'),
(3, DATE_SUB(CURDATE(), INTERVAL 30 DAY), 'Maloclusion clase II', 'Instalacion de brackets', 'Ajuste mensual');
