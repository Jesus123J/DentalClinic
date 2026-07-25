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
    return strpos($header, 'Bearer ') === 0 ? substr($header, 7) : '';
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

function requireAdmin(): array {
    $user = sessionUser();
    if ($user === null || $user['role'] !== 'admin') {
        respond(['error' => 'solo el administrador puede gestionar usuarios'], 403);
    }
    return $user;
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
    respond([
        'token' => $token,
        'user' => [
            'id' => $user['id'],
            'username' => $user['username'],
            'full_name' => $user['full_name'],
            'role' => $user['role'],
        ],
    ]);
}

if ($path === '/auth/logout' && $method === 'POST') {
    db()->prepare('DELETE FROM sessions WHERE token = ?')->execute([bearerToken()]);
    respond(['ok' => true]);
}

// ---------- Pacientes ----------
if ($path === '/patients' && $method === 'GET') {
    $q = trim($_GET['q'] ?? '');
    if ($q !== '') {
        $stmt = db()->prepare(
            "SELECT * FROM patients
             WHERE CONCAT(first_name, ' ', last_name) LIKE ? OR document_id LIKE ?
             ORDER BY last_name, first_name");
        $stmt->execute(["%$q%", "%$q%"]);
    } else {
        $stmt = db()->query('SELECT * FROM patients ORDER BY last_name, first_name');
    }
    respond($stmt->fetchAll());
}

if ($path === '/patients' && $method === 'POST') {
    $b = body();
    db()->prepare(
        'INSERT INTO patients (first_name, last_name, document_id, phone, email, birth_date, allergies, notes)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)')
        ->execute([
            $b['first_name'] ?? '', $b['last_name'] ?? '', $b['document_id'] ?? null,
            $b['phone'] ?? null, $b['email'] ?? null, $b['birth_date'] ?? null,
            $b['allergies'] ?? null, $b['notes'] ?? null,
        ]);
    respond(['id' => (int)db()->lastInsertId()], 201);
}

if (preg_match('#^/patients/(\d+)$#', $path, $m)) {
    $id = (int)$m[1];
    if ($method === 'GET') {
        $stmt = db()->prepare('SELECT * FROM patients WHERE id = ?');
        $stmt->execute([$id]);
        $p = $stmt->fetch();
        if ($p === false) respond(['error' => 'no existe'], 404);
        respond($p);
    }
    if ($method === 'PUT') {
        $b = body();
        db()->prepare(
            'UPDATE patients SET first_name = ?, last_name = ?, document_id = ?,
             phone = ?, email = ?, birth_date = ?, allergies = ?, notes = ? WHERE id = ?')
            ->execute([
                $b['first_name'] ?? '', $b['last_name'] ?? '', $b['document_id'] ?? null,
                $b['phone'] ?? null, $b['email'] ?? null, $b['birth_date'] ?? null,
                $b['allergies'] ?? null, $b['notes'] ?? null, $id,
            ]);
        respond(['ok' => true]);
    }
    if ($method === 'DELETE') {
        db()->prepare('DELETE FROM patients WHERE id = ?')->execute([$id]);
        respond(['ok' => true]);
    }
}

// ---------- Historia clinica ----------
if ($path === '/clinical-records' && $method === 'GET') {
    $stmt = db()->prepare(
        'SELECT * FROM clinical_records WHERE patient_id = ?
         ORDER BY record_date DESC, id DESC');
    $stmt->execute([(int)($_GET['patientId'] ?? 0)]);
    respond($stmt->fetchAll());
}

if ($path === '/clinical-records' && $method === 'POST') {
    $b = body();
    db()->prepare(
        'INSERT INTO clinical_records (patient_id, record_date, diagnosis, treatment, observations)
         VALUES (?, ?, ?, ?, ?)')
        ->execute([
            $b['patient_id'] ?? 0, $b['record_date'] ?? null,
            $b['diagnosis'] ?? '', $b['treatment'] ?? null, $b['observations'] ?? null,
        ]);
    respond(['id' => (int)db()->lastInsertId()], 201);
}

if (preg_match('#^/clinical-records/(\d+)$#', $path, $m) && $method === 'DELETE') {
    db()->prepare('DELETE FROM clinical_records WHERE id = ?')->execute([(int)$m[1]]);
    respond(['ok' => true]);
}

// ---------- Citas ----------
if ($path === '/appointments' && $method === 'GET') {
    $stmt = db()->prepare(
        "SELECT a.*, CONCAT(p.first_name, ' ', p.last_name) AS patient_name
         FROM appointments a JOIN patients p ON p.id = a.patient_id
         WHERE DATE(a.date_time) = ? ORDER BY a.date_time");
    $stmt->execute([$_GET['date'] ?? date('Y-m-d')]);
    respond($stmt->fetchAll());
}

if ($path === '/appointments' && $method === 'POST') {
    $b = body();
    db()->prepare(
        'INSERT INTO appointments (patient_id, date_time, reason, status) VALUES (?, ?, ?, ?)')
        ->execute([
            $b['patient_id'] ?? 0, $b['date_time'] ?? null,
            $b['reason'] ?? null, $b['status'] ?? 'pendiente',
        ]);
    respond(['id' => (int)db()->lastInsertId()], 201);
}

if (preg_match('#^/appointments/(\d+)/status$#', $path, $m) && $method === 'PATCH') {
    $b = body();
    db()->prepare('UPDATE appointments SET status = ? WHERE id = ?')
        ->execute([$b['status'] ?? 'pendiente', (int)$m[1]]);
    respond(['ok' => true]);
}

if (preg_match('#^/appointments/(\d+)$#', $path, $m) && $method === 'DELETE') {
    db()->prepare('DELETE FROM appointments WHERE id = ?')->execute([(int)$m[1]]);
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
        'SELECT id, username, full_name, role, active FROM users ORDER BY username'
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
    respond(['id' => (int)db()->lastInsertId()], 201);
}

if (preg_match('#^/users/(\d+)/active$#', $path, $m) && $method === 'PATCH') {
    requireAdmin();
    $id = (int)$m[1];
    $stmt = db()->prepare('SELECT role FROM users WHERE id = ?');
    $stmt->execute([$id]);
    $target = $stmt->fetch();
    if ($target === false) respond(['error' => 'no existe'], 404);
    if ($target['role'] === 'admin') {
        respond(['error' => 'no se puede deshabilitar al administrador'], 403);
    }
    $b = body();
    db()->prepare('UPDATE users SET active = ? WHERE id = ?')
        ->execute([($b['active'] ?? false) === true ? 1 : 0, $id]);
    respond(['ok' => true]);
}

respond(['error' => 'ruta no encontrada: ' . $path], 404);
