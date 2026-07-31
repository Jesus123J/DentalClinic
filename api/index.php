<?php
/**
 * ProDentist Peru — API REST en PHP (compatible con cPanel).
 * Mismos endpoints que server/bin/server.dart (version Dart para desarrollo).
 *
 * Prueba local:  php -S localhost:8091 index.php   (desde la carpeta api/)
 * En cPanel:     subir la carpeta api/ y ajustar config.php
 */

// ---------- CORS ----------
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Max-Age: 86400');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}
header('Content-Type: application/json; charset=utf-8');

// ---------- Utilidades ----------
function respond($data, int $status = 200): void {
    http_response_code($status);
    echo json_encode($data);
    exit;
}

function body(): array {
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $cfg = require __DIR__ . '/config.php';
        $dsn = "mysql:host={$cfg['db_host']};port={$cfg['db_port']};dbname={$cfg['db_name']};charset=utf8mb4";
        try {
            $pdo = new PDO($dsn, $cfg['db_user'], $cfg['db_pass'], [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            ]);
            // Los tokens viven en MySQL porque PHP no conserva memoria entre peticiones.
            $pdo->exec('CREATE TABLE IF NOT EXISTS sessions (
                token VARCHAR(64) PRIMARY KEY,
                user_id INT NOT NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                CONSTRAINT fk_sessions_user FOREIGN KEY (user_id)
                  REFERENCES users(id) ON DELETE CASCADE
            )');
        } catch (PDOException $e) {
            respond(['error' => 'No se pudo conectar a MySQL: ' . $e->getMessage()], 500);
        }
    }
    return $pdo;
}

function bearerToken(): string {
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (strpos($header, 'Bearer ') === 0) return substr($header, 7);
    // Fallback ?token= para enlaces de descarga abiertos en el navegador.
    return $_GET['token'] ?? '';
}

/** Usuario de la sesion actual o null. */
function sessionUser(): ?array {
    $token = bearerToken();
    if ($token === '') return null;
    $stmt = db()->prepare(
        'SELECT u.id, u.username, u.full_name, u.role
         FROM sessions s JOIN users u ON u.id = s.user_id
         WHERE s.token = ?'
    );
    $stmt->execute([$token]);
    $user = $stmt->fetch();
    return $user === false ? null : $user;
}

require_once __DIR__ . '/permissions.php';

/** Corta la peticion si el usuario no tiene el permiso indicado. */
function requirePermission(string $permission): array {
    $user = sessionUser();
    if ($user === null) respond(['error' => 'no autorizado'], 401);
    if (!roleCan($user['role'], $permission)) {
        $what = PERMISSION_LABELS[$permission] ?? $permission;
        respond([
            'error' => "tu rol ({$user['role']}) no tiene permiso para $what",
        ], 403);
    }
    return $user;
}

function requireAdmin(): array {
    return requirePermission('users.manage');
}

/** Deja constancia de la operacion en la bitacora de auditoria. */
function audit(string $action, string $entity, ?int $entityId,
               ?string $description = null, ?string $reason = null): void {
    $user = sessionUser();
    db()->prepare(
        'INSERT INTO audit_log
         (user_id, user_name, user_role, action, entity, entity_id, description, reason)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)')
        ->execute([
            $user['id'] ?? null, $user['full_name'] ?? null,
            $user['role'] ?? null, $action, $entity, $entityId,
            $description, $reason,
        ]);
}

/**
 * Baja logica: el registro desaparece para la app pero sigue en la base.
 * Exige un motivo y queda auditado; solo 'sistemas' puede reactivarlo.
 */
function softDelete(string $table, int $id, string $entity): void {
    $b = body();
    $reason = trim($b['reason'] ?? '');
    if ($reason === '') {
        respond(['error' => 'debes indicar el motivo de la baja'], 400);
    }
    $user = sessionUser();
    db()->prepare(
        "UPDATE $table SET active = 0, deactivated_at = NOW(),
         deactivated_by = ?, deactivate_reason = ? WHERE id = ?")
        ->execute([$user['full_name'] ?? null, $reason, $id]);
    audit('desactivar', $entity, $id, null, $reason);
}

// ---------- Ruta ----------
$method = $_SERVER['REQUEST_METHOD'];
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
// Quita el prefijo hasta la carpeta del script (soporta /api en cPanel y raiz en php -S).
$base = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'])), '/');
if ($base !== '' && strpos($path, $base) === 0) {
    $path = substr($path, strlen($base));
}
$path = '/' . trim($path, '/');

// ---------- Autenticacion obligatoria (excepto rutas publicas) ----------
$public = ['/health', '/auth/login'];
if (!in_array($path, $public, true) && sessionUser() === null) {
    respond(['error' => 'no autorizado'], 401);
}

// ---------- Endpoints ----------
if ($path === '/health' && $method === 'GET') {
    respond(['ok' => true]);
}

if ($path === '/auth/login' && $method === 'POST') {
    $b = body();
    $stmt = db()->prepare('SELECT * FROM users WHERE username = ?');
    $stmt->execute([$b['username'] ?? '']);
    $user = $stmt->fetch();
    if ($user === false ||
        hash('sha256', $user['salt'] . ($b['password'] ?? '')) !== $user['password_hash']) {
        respond(['error' => 'Usuario o contrasena incorrectos'], 401);
    }
    if ((string)$user['active'] === '0') {
        respond(['error' => 'Cuenta deshabilitada'], 401);
    }
    $token = bin2hex(random_bytes(32));
    db()->prepare('INSERT INTO sessions (token, user_id) VALUES (?, ?)')
        ->execute([$token, $user['id']]);
    db()->prepare(
        'INSERT INTO audit_log (user_id, user_name, user_role, action, entity)
         VALUES (?, ?, ?, ?, ?)')
        ->execute([$user['id'], $user['full_name'], $user['role'],
                   'inicio de sesion', 'sesion']);
    respond([
        'token' => $token,
        'user' => [
            'id' => $user['id'],
            'username' => $user['username'],
            'full_name' => $user['full_name'],
            'role' => $user['role'],
        ],
        // La app usa esto para mostrar solo lo que el rol puede hacer
        'permissions' => permissionsOf($user['role']),
    ]);
}

if ($path === '/auth/logout' && $method === 'POST') {
    db()->prepare('DELETE FROM sessions WHERE token = ?')->execute([bearerToken()]);
    respond(['ok' => true]);
}

// ---------- Pacientes ----------
if ($path === '/patients' && $method === 'GET') {
    requirePermission('patients.view');
    $q = trim($_GET['q'] ?? '');
    if ($q !== '') {
        $stmt = db()->prepare(
            "SELECT * FROM patients
             WHERE active = 1 AND (CONCAT(first_name, ' ', last_name) LIKE ?
                                   OR document_id LIKE ?)
             ORDER BY last_name, first_name");
        $stmt->execute(["%$q%", "%$q%"]);
    } else {
        $stmt = db()->query(
            'SELECT * FROM patients WHERE active = 1 ORDER BY last_name, first_name');
    }
    respond($stmt->fetchAll());
}

if ($path === '/patients' && $method === 'POST') {
    requirePermission('patients.edit');
    $b = body();
    db()->prepare(
        'INSERT INTO patients (first_name, last_name, document_id, phone, email, birth_date, allergies, notes)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)')
        ->execute([
            $b['first_name'] ?? '', $b['last_name'] ?? '', $b['document_id'] ?? null,
            $b['phone'] ?? null, $b['email'] ?? null, $b['birth_date'] ?? null,
            $b['allergies'] ?? null, $b['notes'] ?? null,
        ]);
    $newId = (int)db()->lastInsertId();
    audit('crear', 'paciente', $newId,
        trim(($b['first_name'] ?? '') . ' ' . ($b['last_name'] ?? '')));
    respond(['id' => $newId], 201);
}

if (preg_match('#^/patients/(\d+)$#', $path, $m)) {
    $id = (int)$m[1];
    if ($method === 'GET') {
        requirePermission('patients.view');
        $stmt = db()->prepare('SELECT * FROM patients WHERE id = ?');
        $stmt->execute([$id]);
        $p = $stmt->fetch();
        if ($p === false) respond(['error' => 'no existe'], 404);
        respond($p);
    }
    if ($method === 'PUT') {
        requirePermission('patients.edit');
        $b = body();
        db()->prepare(
            'UPDATE patients SET first_name = ?, last_name = ?, document_id = ?,
             phone = ?, email = ?, birth_date = ?, allergies = ?, notes = ? WHERE id = ?')
            ->execute([
                $b['first_name'] ?? '', $b['last_name'] ?? '', $b['document_id'] ?? null,
                $b['phone'] ?? null, $b['email'] ?? null, $b['birth_date'] ?? null,
                $b['allergies'] ?? null, $b['notes'] ?? null, $id,
            ]);
        audit('editar', 'paciente', $id,
            trim(($b['first_name'] ?? '') . ' ' . ($b['last_name'] ?? '')));
        respond(['ok' => true]);
    }
    if ($method === 'DELETE') {
        requirePermission('patients.deactivate');
        softDelete('patients', $id, 'paciente');
        respond(['ok' => true]);
    }
}

// ---------- Historia clinica ----------
if ($path === '/clinical-records' && $method === 'GET') {
    requirePermission('clinical.view');
    $stmt = db()->prepare(
        'SELECT * FROM clinical_records WHERE patient_id = ? AND active = 1
         ORDER BY record_date DESC, id DESC');
    $stmt->execute([(int)($_GET['patientId'] ?? 0)]);
    respond($stmt->fetchAll());
}

if ($path === '/clinical-records' && $method === 'POST') {
    requirePermission('clinical.edit');
    $b = body();
    db()->prepare(
        'INSERT INTO clinical_records
         (patient_id, record_date, diagnosis, tooth, procedure_type,
          chief_complaint, clinical_exam, treatment, prescription, observations)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
        ->execute([
            $b['patient_id'] ?? 0, $b['record_date'] ?? null,
            $b['diagnosis'] ?? '', $b['tooth'] ?? null,
            $b['procedure_type'] ?? null, $b['chief_complaint'] ?? null,
            $b['clinical_exam'] ?? null, $b['treatment'] ?? null,
            $b['prescription'] ?? null, $b['observations'] ?? null,
        ]);
    $newId = (int)db()->lastInsertId();
    audit('crear', 'registro clinico', $newId, $b['diagnosis'] ?? null);
    respond(['id' => $newId], 201);
}

if (preg_match('#^/clinical-records/(\d+)$#', $path, $m) && $method === 'DELETE') {
    requirePermission('clinical.deactivate');
    softDelete('clinical_records', (int)$m[1], 'registro clinico');
    respond(['ok' => true]);
}

// ---------- Archivos adjuntos de la historia clinica ----------
if ($path === '/attachments' && $method === 'GET') {
    requirePermission('attachments.view');
    $stmt = db()->prepare(
        'SELECT id, patient_id, original_name, mime, size, uploaded_at
         FROM attachments WHERE patient_id = ? AND active = 1
         ORDER BY uploaded_at DESC');
    $stmt->execute([(int)($_GET['patientId'] ?? 0)]);
    respond($stmt->fetchAll());
}

if ($path === '/attachments' && $method === 'POST') {
    requirePermission('attachments.upload');
    if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
        respond(['error' => 'archivo no recibido'], 400);
    }
    $orig = $_FILES['file']['name'];
    $ext = strtolower(pathinfo($orig, PATHINFO_EXTENSION));
    $allowed = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'pdf'];
    if (!in_array($ext, $allowed, true)) {
        respond(['error' => 'tipo no permitido: use imagenes o PDF'], 400);
    }
    if ($_FILES['file']['size'] > 15 * 1024 * 1024) {
        respond(['error' => 'el archivo supera los 15 MB'], 400);
    }
    $dir = __DIR__ . '/uploads';
    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
        // los archivos solo se sirven a traves de la API (con token)
        file_put_contents("$dir/.htaccess", "Require all denied\n");
    }
    $stored = uniqid('att_', true) . '.' . $ext;
    if (!move_uploaded_file($_FILES['file']['tmp_name'], "$dir/$stored")) {
        respond(['error' => 'no se pudo guardar el archivo'], 500);
    }
    db()->prepare(
        'INSERT INTO attachments (patient_id, original_name, stored_name, mime, size)
         VALUES (?, ?, ?, ?, ?)')
        ->execute([
            (int)($_POST['patient_id'] ?? 0), $orig, $stored,
            $_FILES['file']['type'] ?: 'application/octet-stream',
            $_FILES['file']['size'],
        ]);
    respond(['id' => (int)db()->lastInsertId()], 201);
}

if (preg_match('#^/attachments/(\d+)/download$#', $path, $m) && $method === 'GET') {
    $stmt = db()->prepare('SELECT * FROM attachments WHERE id = ?');
    $stmt->execute([(int)$m[1]]);
    $att = $stmt->fetch();
    if ($att === false) respond(['error' => 'no existe'], 404);
    $file = __DIR__ . '/uploads/' . $att['stored_name'];
    if (!is_file($file)) respond(['error' => 'archivo no encontrado'], 404);
    header('Content-Type: ' . $att['mime']);
    header('Content-Length: ' . filesize($file));
    header('Content-Disposition: inline; filename="' . $att['original_name'] . '"');
    readfile($file);
    exit;
}

if (preg_match('#^/attachments/(\d+)$#', $path, $m) && $method === 'DELETE') {
    requirePermission('attachments.deactivate');
    // El archivo fisico se conserva: la baja es logica y reversible.
    softDelete('attachments', (int)$m[1], 'archivo adjunto');
    respond(['ok' => true]);
}

// ---------- Historia clinica formal (formato peruano, 8 secciones) ----------
const HISTORY_JSON_FIELDS = [
    'biological_functions', 'personal_general', 'personal_physiological',
    'rasa', 'general_exam', 'extraoral_exam', 'intraoral_exam',
];

const HISTORY_FIELDS = [
    'hc_number', 'birth_place', 'origin', 'occupation', 'trips_last_year',
    'emergency_contact', 'chief_complaint', 'illness_time', 'illness_onset',
    'illness_course', 'illness_signs', 'illness_story', 'biological_functions',
    'risks', 'personal_general', 'personal_physiological',
    'path_hypertension', 'path_cardiovascular', 'path_diabetes',
    'path_endocrine', 'path_asthma', 'path_hepatitis', 'path_liver',
    'path_kidney', 'path_tbc', 'path_infectious', 'path_bleeding',
    'path_other', 'path_medication', 'allergy_drugs', 'allergy_food',
    'allergy_detail', 'previous_surgeries', 'previous_hospitalizations',
    'habit_tobacco', 'habit_alcohol', 'habit_drugs', 'is_pregnant',
    'pregnancy_month', 'pathological_notes', 'last_dental_visit',
    'previous_dental_treatments', 'previous_anesthesia', 'anesthesia_reaction',
    'anesthesia_reaction_detail', 'previous_extractions',
    'extraction_complications', 'extraction_complication_detail',
    'stomatological_notes', 'family_history', 'rasa', 'ectoscopy',
    'vital_blood_pressure', 'vital_pulse', 'vital_heart_rate',
    'vital_respiratory_rate', 'vital_temperature', 'general_exam',
    'extraoral_exam', 'intraoral_exam', 'lesion_map',
    'presumptive_diagnosis', 'diagnostic_plan', 'auxiliary_exams',
    'definitive_diagnosis', 'treatment_plan', 'performed_treatments',
    'dentist_name', 'dentist_cop',
];

if (preg_match('#^/patients/(\d+)/history$#', $path, $m) && $method === 'GET') {
    requirePermission('clinical.view');
    $stmt = db()->prepare('SELECT * FROM clinical_histories WHERE patient_id = ?');
    $stmt->execute([(int)$m[1]]);
    $row = $stmt->fetch();
    if ($row === false) {
        respond(['exists' => false]);
    }
    foreach (HISTORY_JSON_FIELDS as $f) {
        $row[$f] = $row[$f] === null ? null : json_decode($row[$f], true);
    }
    $row['exists'] = true;
    respond($row);
}

if (preg_match('#^/patients/(\d+)/history$#', $path, $m) && $method === 'PUT') {
    requirePermission('clinical.edit');
    $patientId = (int)$m[1];
    $b = body();
    $user = sessionUser();

    $values = [];
    foreach (HISTORY_FIELDS as $f) {
        $v = $b[$f] ?? null;
        if (in_array($f, HISTORY_JSON_FIELDS, true)) {
            $v = $v === null ? null : json_encode($v, JSON_UNESCAPED_UNICODE);
        } elseif (is_bool($v)) {
            $v = $v ? 1 : 0;
        }
        $values[] = $v;
    }

    $exists = db()->prepare('SELECT id FROM clinical_histories WHERE patient_id = ?');
    $exists->execute([$patientId]);
    if ($exists->fetch() === false) {
        $cols = implode(', ', HISTORY_FIELDS);
        $marks = implode(', ', array_fill(0, count(HISTORY_FIELDS), '?'));
        db()->prepare(
            "INSERT INTO clinical_histories (patient_id, updated_by, $cols)
             VALUES (?, ?, $marks)")
            ->execute(array_merge([$patientId, $user['full_name'] ?? null], $values));
        audit('crear', 'historia clinica', $patientId);
    } else {
        $sets = implode(' = ?, ', HISTORY_FIELDS) . ' = ?';
        db()->prepare(
            "UPDATE clinical_histories SET updated_by = ?, $sets WHERE patient_id = ?")
            ->execute(array_merge([$user['full_name'] ?? null], $values, [$patientId]));
        audit('editar', 'historia clinica', $patientId);
    }
    respond(['ok' => true]);
}

// ---------- Odontograma ----------
if ($path === '/odontogram' && $method === 'GET') {
    requirePermission('clinical.view');
    $stmt = db()->prepare('SELECT * FROM odontogram WHERE patient_id = ?');
    $stmt->execute([(int)($_GET['patientId'] ?? 0)]);
    respond($stmt->fetchAll());
}

if ($path === '/odontogram' && $method === 'PUT') {
    requirePermission('clinical.edit');
    $b = body();
    $patientId = (int)($b['patient_id'] ?? 0);
    $tooth = $b['tooth'] ?? '';
    // NTS 150-MINSA-2019: el hallazgo puede ser de la pieza completa o de
    // una cara (vestibular, lingual/palatina, mesial, distal, oclusal).
    $surface = $b['surface'] ?? 'completa';
    // La denticion se deduce del numero FDI: 51-85 son piezas deciduas.
    $toothNumber = (int)$tooth;
    $dentition = ($toothNumber >= 51 && $toothNumber <= 85)
        ? 'decidua' : 'permanente';
    $status = $b['status'] ?? 'sano';
    $note = $b['note'] ?? null;

    // Estado anterior, para dejar constancia del cambio
    $prev = db()->prepare(
        'SELECT status FROM odontogram
         WHERE patient_id = ? AND tooth = ? AND surface = ?');
    $prev->execute([$patientId, $tooth, $surface]);
    $prevRow = $prev->fetch();
    $previous = $prevRow === false ? 'sano' : $prevRow['status'];

    if ($status === 'sano') {
        // sano = estado por defecto: se quita el registro de esa cara
        db()->prepare(
            'DELETE FROM odontogram
             WHERE patient_id = ? AND tooth = ? AND surface = ?')
            ->execute([$patientId, $tooth, $surface]);
    } else {
        db()->prepare(
            'INSERT INTO odontogram (patient_id, tooth, surface, dentition, status, note)
             VALUES (?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE status = VALUES(status),
                                     note = VALUES(note),
                                     dentition = VALUES(dentition)')
            ->execute([$patientId, $tooth, $surface, $dentition, $status, $note]);
    }

    // Solo se registra en el historial si algo cambio realmente
    if ($previous !== $status) {
        $user = sessionUser();
        db()->prepare(
            'INSERT INTO odontogram_history
             (patient_id, tooth, surface, previous_status, status, note,
              user_id, user_name)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)')
            ->execute([
                $patientId, $tooth, $surface, $previous, $status, $note,
                $user['id'] ?? null, $user['full_name'] ?? null,
            ]);
    }
    respond(['ok' => true]);
}

// Especificaciones y observaciones del odontograma (pie del formato oficial)
if ($path === '/odontogram/notes' && $method === 'GET') {
    requirePermission('clinical.view');
    $stmt = db()->prepare('SELECT * FROM odontogram_notes WHERE patient_id = ?');
    $stmt->execute([(int)($_GET['patientId'] ?? 0)]);
    $row = $stmt->fetch();
    respond($row === false
        ? ['specifications' => null, 'observations' => null]
        : $row);
}

if ($path === '/odontogram/notes' && $method === 'PUT') {
    requirePermission('clinical.edit');
    $b = body();
    $user = sessionUser();
    db()->prepare(
        'INSERT INTO odontogram_notes
         (patient_id, specifications, observations, updated_by)
         VALUES (?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE specifications = VALUES(specifications),
                                 observations = VALUES(observations),
                                 updated_by = VALUES(updated_by)')
        ->execute([
            (int)($b['patient_id'] ?? 0), $b['specifications'] ?? null,
            $b['observations'] ?? null, $user['full_name'] ?? null,
        ]);
    respond(['ok' => true]);
}

// Historial de cambios del odontograma (todo el paciente o una pieza)
if ($path === '/odontogram/history' && $method === 'GET') {
    $patientId = (int)($_GET['patientId'] ?? 0);
    $tooth = $_GET['tooth'] ?? null;
    if ($tooth !== null && $tooth !== '') {
        $stmt = db()->prepare(
            'SELECT * FROM odontogram_history
             WHERE patient_id = ? AND tooth = ? ORDER BY changed_at DESC, id DESC');
        $stmt->execute([$patientId, $tooth]);
    } else {
        $stmt = db()->prepare(
            'SELECT * FROM odontogram_history WHERE patient_id = ?
             ORDER BY changed_at DESC, id DESC LIMIT 200');
        $stmt->execute([$patientId]);
    }
    respond($stmt->fetchAll());
}

// ---------- Citas ----------
if ($path === '/appointments' && $method === 'GET') {
    requirePermission('appointments.view');
    // Por dia (?date=) o por rango (?from=&to=) para el calendario.
    if (isset($_GET['from'], $_GET['to'])) {
        $stmt = db()->prepare(
            "SELECT a.*, CONCAT(p.first_name, ' ', p.last_name) AS patient_name
             FROM appointments a JOIN patients p ON p.id = a.patient_id
             WHERE a.active = 1 AND DATE(a.date_time) BETWEEN ? AND ?
             ORDER BY a.date_time");
        $stmt->execute([$_GET['from'], $_GET['to']]);
    } else {
        $stmt = db()->prepare(
            "SELECT a.*, CONCAT(p.first_name, ' ', p.last_name) AS patient_name
             FROM appointments a JOIN patients p ON p.id = a.patient_id
             WHERE a.active = 1 AND DATE(a.date_time) = ? ORDER BY a.date_time");
        $stmt->execute([$_GET['date'] ?? date('Y-m-d')]);
    }
    respond($stmt->fetchAll());
}

if ($path === '/appointments' && $method === 'POST') {
    requirePermission('appointments.edit');
    $b = body();
    db()->prepare(
        'INSERT INTO appointments (patient_id, date_time, reason, status) VALUES (?, ?, ?, ?)')
        ->execute([
            $b['patient_id'] ?? 0, $b['date_time'] ?? null,
            $b['reason'] ?? null, $b['status'] ?? 'pendiente',
        ]);
    $newId = (int)db()->lastInsertId();
    audit('crear', 'cita', $newId, $b['date_time'] ?? null);
    respond(['id' => $newId], 201);
}

if (preg_match('#^/appointments/(\d+)/status$#', $path, $m) && $method === 'PATCH') {
    requirePermission('appointments.edit');
    $b = body();
    $status = $b['status'] ?? 'pendiente';
    db()->prepare('UPDATE appointments SET status = ? WHERE id = ?')
        ->execute([$status, (int)$m[1]]);
    audit('cambiar estado', 'cita', (int)$m[1], "estado: $status");
    respond(['ok' => true]);
}

if (preg_match('#^/appointments/(\d+)$#', $path, $m) && $method === 'DELETE') {
    requirePermission('appointments.deactivate');
    softDelete('appointments', (int)$m[1], 'cita');
    respond(['ok' => true]);
}

// ---------- Catalogo de tratamientos ----------
if ($path === '/treatments' && $method === 'GET') {
    requirePermission('sales.view');
    respond(db()->query(
        'SELECT * FROM treatments WHERE active = 1 ORDER BY name')->fetchAll());
}

if ($path === '/treatments' && $method === 'POST') {
    requirePermission('treatments.manage');
    $b = body();
    db()->prepare(
        'INSERT INTO treatments (name, description, price) VALUES (?, ?, ?)')
        ->execute([$b['name'] ?? '', $b['description'] ?? null, $b['price'] ?? 0]);
    $newId = (int)db()->lastInsertId();
    audit('crear', 'servicio', $newId, $b['name'] ?? null);
    respond(['id' => $newId], 201);
}

if (preg_match('#^/treatments/(\d+)$#', $path, $m)) {
    $id = (int)$m[1];
    if ($method === 'PUT') {
        requirePermission('treatments.manage');
        $b = body();
        db()->prepare(
            'UPDATE treatments SET name = ?, description = ?, price = ? WHERE id = ?')
            ->execute([$b['name'] ?? '', $b['description'] ?? null, $b['price'] ?? 0, $id]);
        audit('editar', 'servicio', $id, $b['name'] ?? null);
        respond(['ok' => true]);
    }
    if ($method === 'DELETE') {
        requirePermission('treatments.manage');
        softDelete('treatments', $id, 'servicio');
        respond(['ok' => true]);
    }
}

// ---------- Cobros / ventas ----------
if ($path === '/sales' && $method === 'GET') {
    requirePermission('sales.view');
    $from = $_GET['from'] ?? date('Y-m-01');
    $to = $_GET['to'] ?? date('Y-m-d');
    $stmt = db()->prepare(
        "SELECT s.*, CONCAT(p.first_name, ' ', p.last_name) AS patient_name
         FROM sales s LEFT JOIN patients p ON p.id = s.patient_id
         WHERE s.active = 1 AND DATE(s.created_at) BETWEEN ? AND ?
         ORDER BY s.created_at DESC");
    $stmt->execute([$from, $to]);
    respond($stmt->fetchAll());
}

if ($path === '/sales' && $method === 'POST') {
    requirePermission('sales.create');
    $b = body();
    $items = $b['items'] ?? [];
    if (!is_array($items) || count($items) === 0) {
        respond(['error' => 'agregue al menos un servicio'], 400);
    }
    $total = 0;
    foreach ($items as $it) {
        $total += (float)($it['price'] ?? 0) * (int)($it['qty'] ?? 1);
    }
    $user = sessionUser();
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $pdo->prepare(
            'INSERT INTO sales (patient_id, user_id, total, paid, method, status, note)
             VALUES (?, ?, ?, ?, ?, ?, ?)')
            ->execute([
                $b['patient_id'] ?: null, $user['id'] ?? null, $total,
                $b['paid'] ?? $total, $b['method'] ?? 'efectivo',
                $b['status'] ?? 'pagado', $b['note'] ?? null,
            ]);
        $saleId = (int)$pdo->lastInsertId();
        $stmt = $pdo->prepare(
            'INSERT INTO sale_items (sale_id, treatment_id, name, price, qty)
             VALUES (?, ?, ?, ?, ?)');
        foreach ($items as $it) {
            $stmt->execute([
                $saleId, $it['treatment_id'] ?: null, $it['name'] ?? '',
                $it['price'] ?? 0, $it['qty'] ?? 1,
            ]);
        }
        $pdo->commit();
        audit('crear', 'cobro', $saleId, 'total S/ ' . number_format($total, 2));
        respond(['id' => $saleId, 'total' => $total], 201);
    } catch (Exception $e) {
        $pdo->rollBack();
        respond(['error' => 'no se pudo registrar el cobro'], 500);
    }
}

if (preg_match('#^/sales/(\d+)$#', $path, $m) && $method === 'GET') {
    requirePermission('sales.view');
    $stmt = db()->prepare(
        "SELECT s.*, CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
                p.document_id
         FROM sales s LEFT JOIN patients p ON p.id = s.patient_id WHERE s.id = ?");
    $stmt->execute([(int)$m[1]]);
    $sale = $stmt->fetch();
    if ($sale === false) respond(['error' => 'no existe'], 404);
    $items = db()->prepare('SELECT * FROM sale_items WHERE sale_id = ?');
    $items->execute([(int)$m[1]]);
    $sale['items'] = $items->fetchAll();
    respond($sale);
}

// Registrar pago (total o abono parcial) de un cobro pendiente.
if (preg_match('#^/sales/(\d+)/payment$#', $path, $m) && $method === 'PATCH') {
    requirePermission('sales.payment');
    $id = (int)$m[1];
    $stmt = db()->prepare('SELECT total, paid, status FROM sales WHERE id = ?');
    $stmt->execute([$id]);
    $sale = $stmt->fetch();
    if ($sale === false) respond(['error' => 'no existe'], 404);
    if ($sale['status'] === 'anulado') {
        respond(['error' => 'el cobro esta anulado'], 400);
    }
    $b = body();
    // Sin monto = se salda el total pendiente.
    $amount = isset($b['amount']) ? (float)$b['amount']
        : (float)$sale['total'] - (float)$sale['paid'];
    if ($amount <= 0) respond(['error' => 'monto invalido'], 400);

    $paid = min((float)$sale['paid'] + $amount, (float)$sale['total']);
    $status = $paid >= (float)$sale['total'] ? 'pagado' : 'pendiente';
    $params = [$paid, $status, $id];
    $sql = 'UPDATE sales SET paid = ?, status = ?';
    if (!empty($b['method'])) {
        $sql .= ', method = ?';
        $params = [$paid, $status, $b['method'], $id];
    }
    $sql .= ' WHERE id = ?';
    db()->prepare($sql)->execute($params);
    audit('registrar pago', 'cobro', $id,
        'pagado S/ ' . number_format($paid, 2) . " - $status");
    respond(['ok' => true, 'paid' => $paid, 'status' => $status]);
}

if (preg_match('#^/sales/(\d+)$#', $path, $m) && $method === 'DELETE') {
    requirePermission('sales.void');
    $id = (int)$m[1];
    $b = body();
    $reason = trim($b['reason'] ?? '');
    if ($reason === '') {
        respond(['error' => 'debes indicar el motivo de la anulacion'], 400);
    }
    $user = sessionUser();
    db()->prepare(
        "UPDATE sales SET status = 'anulado', deactivated_at = NOW(),
         deactivated_by = ?, deactivate_reason = ? WHERE id = ?")
        ->execute([$user['full_name'] ?? null, $reason, $id]);
    audit('anular', 'cobro', $id, null, $reason);
    respond(['ok' => true]);
}

// ---------- Gastos ----------
if ($path === '/expenses' && $method === 'GET') {
    requirePermission('expenses.manage');
    $from = $_GET['from'] ?? date('Y-m-01');
    $to = $_GET['to'] ?? date('Y-m-d');
    $stmt = db()->prepare(
        'SELECT * FROM expenses WHERE active = 1 AND spent_at BETWEEN ? AND ?
         ORDER BY spent_at DESC, id DESC');
    $stmt->execute([$from, $to]);
    respond($stmt->fetchAll());
}

if ($path === '/expenses' && $method === 'POST') {
    requirePermission('expenses.manage');
    $b = body();
    $user = sessionUser();
    db()->prepare(
        'INSERT INTO expenses (concept, category, amount, spent_at, user_id)
         VALUES (?, ?, ?, ?, ?)')
        ->execute([
            $b['concept'] ?? '', $b['category'] ?? 'General',
            $b['amount'] ?? 0, $b['spent_at'] ?? date('Y-m-d'),
            $user['id'] ?? null,
        ]);
    $newId = (int)db()->lastInsertId();
    audit('crear', 'gasto', $newId, $b['concept'] ?? null);
    respond(['id' => $newId], 201);
}

if (preg_match('#^/expenses/(\d+)$#', $path, $m) && $method === 'DELETE') {
    requirePermission('expenses.manage');
    softDelete('expenses', (int)$m[1], 'gasto');
    respond(['ok' => true]);
}

// ---------- Finanzas: resumen, series y ranking ----------
if ($path === '/finance/summary' && $method === 'GET') {
    requirePermission('finance.view');
    $from = $_GET['from'] ?? date('Y-m-01');
    $to = $_GET['to'] ?? date('Y-m-d');

    $inc = db()->prepare(
        "SELECT COALESCE(SUM(total),0) AS income, COUNT(*) AS count
         FROM sales WHERE status <> 'anulado' AND DATE(created_at) BETWEEN ? AND ?");
    $inc->execute([$from, $to]);
    $income = $inc->fetch();

    $exp = db()->prepare(
        'SELECT COALESCE(SUM(amount),0) AS expenses FROM expenses
         WHERE spent_at BETWEEN ? AND ?');
    $exp->execute([$from, $to]);
    $expenses = (float)$exp->fetch()['expenses'];

    $today = db()->query(
        "SELECT COALESCE(SUM(total),0) AS t FROM sales
         WHERE status <> 'anulado' AND DATE(created_at) = CURDATE()")->fetch();

    $pend = db()->prepare(
        "SELECT COALESCE(SUM(total - paid),0) AS due FROM sales
         WHERE status = 'pendiente' AND DATE(created_at) BETWEEN ? AND ?");
    $pend->execute([$from, $to]);

    // Serie mensual de los ultimos 6 meses (ingresos vs gastos)
    $series = [];
    for ($i = 5; $i >= 0; $i--) {
        $month = date('Y-m', strtotime("-$i month"));
        $si = db()->prepare(
            "SELECT COALESCE(SUM(total),0) AS v FROM sales
             WHERE status <> 'anulado' AND DATE_FORMAT(created_at, '%Y-%m') = ?");
        $si->execute([$month]);
        $se = db()->prepare(
            "SELECT COALESCE(SUM(amount),0) AS v FROM expenses
             WHERE DATE_FORMAT(spent_at, '%Y-%m') = ?");
        $se->execute([$month]);
        $series[] = [
            'month' => $month,
            'income' => (float)$si->fetch()['v'],
            'expenses' => (float)$se->fetch()['v'],
        ];
    }

    // Tratamientos mas vendidos del rango
    $top = db()->prepare(
        "SELECT i.name, SUM(i.qty) AS qty, SUM(i.price * i.qty) AS amount
         FROM sale_items i JOIN sales s ON s.id = i.sale_id
         WHERE s.status <> 'anulado' AND DATE(s.created_at) BETWEEN ? AND ?
         GROUP BY i.name ORDER BY amount DESC LIMIT 6");
    $top->execute([$from, $to]);

    respond([
        'income' => (float)$income['income'],
        'sales_count' => (int)$income['count'],
        'expenses' => $expenses,
        'profit' => (float)$income['income'] - $expenses,
        'today' => (float)$today['t'],
        'pending' => (float)$pend->fetch()['due'],
        'series' => $series,
        'top_treatments' => $top->fetchAll(),
    ]);
}

// ---------- Resumen economico y de visitas de un paciente ----------
if (preg_match('#^/patients/(\d+)/summary$#', $path, $m) && $method === 'GET') {
    $id = (int)$m[1];

    $tot = db()->prepare(
        "SELECT COALESCE(SUM(total),0) AS spent,
                COALESCE(SUM(total - paid),0) AS due,
                COUNT(*) AS sales_count
         FROM sales WHERE patient_id = ? AND status <> 'anulado'");
    $tot->execute([$id]);
    $totals = $tot->fetch();

    $visits = db()->prepare(
        "SELECT COUNT(*) AS attended,
                MAX(date_time) AS last_visit,
                MIN(date_time) AS first_visit
         FROM appointments WHERE patient_id = ? AND status = 'atendida'");
    $visits->execute([$id]);
    $v = $visits->fetch();

    $next = db()->prepare(
        "SELECT MIN(date_time) AS next_visit FROM appointments
         WHERE patient_id = ? AND status = 'pendiente' AND date_time >= NOW()");
    $next->execute([$id]);

    $recs = db()->prepare(
        'SELECT COUNT(*) AS n FROM clinical_records WHERE patient_id = ?');
    $recs->execute([$id]);

    // Cobros del paciente con el detalle de servicios
    $sales = db()->prepare(
        'SELECT * FROM sales WHERE patient_id = ? ORDER BY created_at DESC');
    $sales->execute([$id]);
    $salesRows = $sales->fetchAll();
    $itemStmt = db()->prepare(
        'SELECT name, price, qty FROM sale_items WHERE sale_id = ?');
    foreach ($salesRows as &$s) {
        $itemStmt->execute([$s['id']]);
        $s['items'] = $itemStmt->fetchAll();
    }
    unset($s);

    // Todas las citas del paciente
    $appts = db()->prepare(
        'SELECT * FROM appointments WHERE patient_id = ? ORDER BY date_time DESC');
    $appts->execute([$id]);

    // Servicios mas realizados a este paciente
    $top = db()->prepare(
        "SELECT i.name, SUM(i.qty) AS qty, SUM(i.price * i.qty) AS amount
         FROM sale_items i JOIN sales s ON s.id = i.sale_id
         WHERE s.patient_id = ? AND s.status <> 'anulado'
         GROUP BY i.name ORDER BY amount DESC");
    $top->execute([$id]);

    respond([
        'spent' => (float)$totals['spent'],
        'due' => (float)$totals['due'],
        'sales_count' => (int)$totals['sales_count'],
        'visits' => (int)$v['attended'],
        'first_visit' => $v['first_visit'],
        'last_visit' => $v['last_visit'],
        'next_visit' => $next->fetch()['next_visit'],
        'records_count' => (int)$recs->fetch()['n'],
        'sales' => $salesRows,
        'appointments' => $appts->fetchAll(),
        'top_treatments' => $top->fetchAll(),
    ]);
}

// ---------- Auditoria: quien hizo que y cuando ----------
if ($path === '/audit' && $method === 'GET') {
    requirePermission('audit.view');
    $where = [];
    $params = [];
    if (!empty($_GET['from'])) {
        $where[] = 'DATE(created_at) >= ?';
        $params[] = $_GET['from'];
    }
    if (!empty($_GET['to'])) {
        $where[] = 'DATE(created_at) <= ?';
        $params[] = $_GET['to'];
    }
    if (!empty($_GET['entity'])) {
        $where[] = 'entity = ?';
        $params[] = $_GET['entity'];
    }
    if (!empty($_GET['user'])) {
        $where[] = 'user_name LIKE ?';
        $params[] = '%' . $_GET['user'] . '%';
    }
    $sql = 'SELECT * FROM audit_log';
    if ($where) $sql .= ' WHERE ' . implode(' AND ', $where);
    $sql .= ' ORDER BY created_at DESC, id DESC LIMIT 500';
    $stmt = db()->prepare($sql);
    $stmt->execute($params);
    respond($stmt->fetchAll());
}

// ---------- Papelera: solo el ingeniero de sistemas ----------
const TRASH_TABLES = [
    'patients' => ["CONCAT(first_name, ' ', last_name)", 'paciente'],
    'appointments' => ['date_time', 'cita'],
    'clinical_records' => ['diagnosis', 'registro clinico'],
    'attachments' => ['original_name', 'archivo adjunto'],
    'sales' => ["CONCAT('Cobro S/ ', total)", 'cobro'],
    'expenses' => ['concept', 'gasto'],
    'treatments' => ['name', 'servicio'],
    'users' => ['full_name', 'usuario'],
];

if ($path === '/trash' && $method === 'GET') {
    requirePermission('trash.view');
    $rows = [];
    foreach (TRASH_TABLES as $table => [$labelExpr, $entity]) {
        $stmt = db()->query(
            "SELECT id, $labelExpr AS label, deactivated_at, deactivated_by,
                    deactivate_reason
             FROM $table WHERE active = 0 ORDER BY deactivated_at DESC");
        foreach ($stmt->fetchAll() as $r) {
            $r['table'] = $table;
            $r['entity'] = $entity;
            $rows[] = $r;
        }
    }
    usort($rows, fn($a, $b) =>
        strcmp($b['deactivated_at'] ?? '', $a['deactivated_at'] ?? ''));
    respond($rows);
}

if (preg_match('#^/trash/([a-z_]+)/(\d+)/restore$#', $path, $m)
        && $method === 'POST') {
    requirePermission('trash.restore');
    $table = $m[1];
    $id = (int)$m[2];
    if (!array_key_exists($table, TRASH_TABLES)) {
        respond(['error' => 'entidad no valida'], 400);
    }
    $b = body();
    $reason = trim($b['reason'] ?? '');
    if ($reason === '') {
        respond(['error' => 'debes indicar el motivo de la reactivacion'], 400);
    }
    $extra = $table === 'sales' ? ", status = 'pagado'" : '';
    db()->prepare(
        "UPDATE $table SET active = 1, deactivated_at = NULL,
         deactivated_by = NULL, deactivate_reason = NULL $extra WHERE id = ?")
        ->execute([$id]);
    audit('reactivar', TRASH_TABLES[$table][1], $id, null, $reason);
    respond(['ok' => true]);
}

// ---------- Reportes ----------
if ($path === '/reports/appointments' && $method === 'GET') {
    $stmt = db()->prepare(
        "SELECT a.date_time, a.reason, a.status,
                CONCAT(p.first_name, ' ', p.last_name) AS patient_name, p.document_id
         FROM appointments a JOIN patients p ON p.id = a.patient_id
         WHERE DATE(a.date_time) BETWEEN ? AND ?
         ORDER BY a.date_time");
    $stmt->execute([$_GET['from'] ?? date('Y-m-d'), $_GET['to'] ?? date('Y-m-d')]);
    respond($stmt->fetchAll());
}

if ($path === '/reports/dashboard' && $method === 'GET') {
    $row = db()->query(
        "SELECT
           (SELECT COUNT(*) FROM patients) AS total_patients,
           (SELECT COUNT(*) FROM appointments WHERE DATE(date_time) = CURDATE()) AS today_appointments,
           (SELECT COUNT(*) FROM appointments WHERE status = 'pendiente') AS pending_appointments"
    )->fetch();
    respond($row);
}

// ---------- Usuarios (solo administrador) ----------
if ($path === '/users' && $method === 'GET') {
    requireAdmin();
    respond(db()->query(
        'SELECT id, username, full_name, role, active FROM users
         WHERE active = 1 OR role IN (\'admin\',\'sistemas\') ORDER BY username'
    )->fetchAll());
}

if ($path === '/users' && $method === 'POST') {
    requireAdmin();
    $b = body();
    $role = $b['role'] ?? '';
    if (!in_array($role, ['recepcion', 'odontologo'], true)) {
        respond(['error' => 'rol invalido: use recepcion u odontologo'], 400);
    }
    $username = trim($b['username'] ?? '');
    $password = $b['password'] ?? '';
    if ($username === '' || strlen($password) < 6) {
        respond(['error' => 'usuario requerido y contrasena de al menos 6 caracteres'], 400);
    }
    $stmt = db()->prepare('SELECT id FROM users WHERE username = ?');
    $stmt->execute([$username]);
    if ($stmt->fetch() !== false) {
        respond(['error' => 'el usuario ya existe'], 409);
    }
    $salt = bin2hex(random_bytes(8));
    db()->prepare(
        'INSERT INTO users (username, password_hash, salt, full_name, role) VALUES (?, ?, ?, ?, ?)')
        ->execute([
            $username, hash('sha256', $salt . $password), $salt,
            $b['full_name'] ?? $username, $role,
        ]);
    $newId = (int)db()->lastInsertId();
    audit('crear', 'usuario', $newId, "$username ($role)");
    respond(['id' => $newId], 201);
}

if (preg_match('#^/users/(\d+)$#', $path, $m) && $method === 'DELETE') {
    requireAdmin();
    $id = (int)$m[1];
    $stmt = db()->prepare('SELECT role FROM users WHERE id = ?');
    $stmt->execute([$id]);
    $target = $stmt->fetch();
    if ($target === false) respond(['error' => 'no existe'], 404);
    if (in_array($target['role'], ['admin', 'sistemas'], true)) {
        respond(['error' => 'no se puede dar de baja a este usuario'], 403);
    }
    // Baja logica: la cuenta se oculta pero conserva su historial de acciones
    softDelete('users', $id, 'usuario');
    respond(['ok' => true]);
}

if (preg_match('#^/users/(\d+)/active$#', $path, $m) && $method === 'PATCH') {
    requireAdmin();
    $id = (int)$m[1];
    $stmt = db()->prepare('SELECT role, full_name FROM users WHERE id = ?');
    $stmt->execute([$id]);
    $target = $stmt->fetch();
    if ($target === false) respond(['error' => 'no existe'], 404);
    if (in_array($target['role'], ['admin', 'sistemas'], true)) {
        respond(['error' => 'no se puede deshabilitar a este usuario'], 403);
    }
    $b = body();
    $enabled = ($b['active'] ?? false) === true;
    db()->prepare('UPDATE users SET active = ? WHERE id = ?')
        ->execute([$enabled ? 1 : 0, $id]);
    audit($enabled ? 'habilitar' : 'deshabilitar', 'usuario', $id,
        $target['full_name'], $b['reason'] ?? null);
    respond(['ok' => true]);
}

respond(['error' => 'ruta no encontrada: ' . $path], 404);
