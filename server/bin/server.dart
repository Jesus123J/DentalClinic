// API REST del sistema odontologico.
// Ejecutar con: dart run bin/server.dart  (desde la carpeta server/)
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// Configuracion de MySQL: ajustar segun la instalacion.
const dbHost = '127.0.0.1';
const dbPort = 3306;
const dbUser = 'root';
const dbPassword = '123456';
const dbName = 'dental_clinic';
const serverPort = 8090;

late final MySQLConnectionPool pool;

/// Sesiones activas: token -> datos del usuario.
final Map<String, Map<String, dynamic>> _sessions = {};
final Random _random = Random.secure();

String _newToken() =>
    base64UrlEncode(List<int>.generate(32, (_) => _random.nextInt(256)));

String _hashPassword(String salt, String password) =>
    sha256.convert(utf8.encode('$salt$password')).toString();

Response _json(Object? data, {int status = 200}) => Response(
      status,
      body: jsonEncode(data),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

List<Map<String, String?>> _rows(IResultSet result) =>
    result.rows.map((r) => r.assoc()).toList();

Future<Map<String, dynamic>> _body(Request request) async =>
    jsonDecode(await request.readAsString()) as Map<String, dynamic>;

Middleware _cors() {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };
  return (Handler handler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }
      final response = await handler(request);
      return response.change(headers: headers);
    };
  };
}

/// Exige un token valido en el header "Authorization: Bearer token",
/// excepto para /health y /auth/login.
Middleware _auth() {
  const publicPaths = {'health', 'auth/login'};
  return (Handler handler) {
    return (Request request) async {
      if (request.method == 'OPTIONS' ||
          publicPaths.contains(request.url.path)) {
        return handler(request);
      }
      final header = request.headers['authorization'] ?? '';
      final token = header.startsWith('Bearer ') ? header.substring(7) : '';
      if (!_sessions.containsKey(token)) {
        return _json({'error': 'no autorizado'}, status: 401);
      }
      return handler(request);
    };
  };
}

Router _buildRouter() {
  final router = Router();

  router.get('/health', (Request _) => _json({'ok': true}));

  // ---------- Autenticacion ----------
  router.post('/auth/login', (Request request) async {
    final b = await _body(request);
    final result = await pool.execute(
      'SELECT * FROM users WHERE username = :username',
      {'username': b['username']},
    );
    if (result.rows.isEmpty) {
      return _json({'error': 'Usuario o contrasena incorrectos'}, status: 401);
    }
    final user = result.rows.first.assoc();
    final hash = _hashPassword(user['salt']!, b['password']?.toString() ?? '');
    if (hash != user['password_hash']) {
      return _json({'error': 'Usuario o contrasena incorrectos'}, status: 401);
    }
    final token = _newToken();
    _sessions[token] = {
      'id': user['id'],
      'username': user['username'],
      'full_name': user['full_name'],
      'role': user['role'],
    };
    return _json({'token': token, 'user': _sessions[token]});
  });

  router.post('/auth/logout', (Request request) async {
    final header = request.headers['authorization'] ?? '';
    _sessions.remove(
        header.startsWith('Bearer ') ? header.substring(7) : '');
    return _json({'ok': true});
  });

  // ---------- Pacientes ----------
  router.get('/patients', (Request request) async {
    final q = request.url.queryParameters['q'];
    var sql = 'SELECT * FROM patients';
    Map<String, dynamic>? params;
    if (q != null && q.trim().isNotEmpty) {
      sql += ''' WHERE CONCAT(first_name, ' ', last_name) LIKE :q
                 OR document_id LIKE :q''';
      params = {'q': '%${q.trim()}%'};
    }
    sql += ' ORDER BY last_name, first_name';
    return _json(_rows(await pool.execute(sql, params)));
  });

  router.get('/patients/<id>', (Request request, String id) async {
    final result = await pool
        .execute('SELECT * FROM patients WHERE id = :id', {'id': id});
    if (result.rows.isEmpty) return _json({'error': 'no existe'}, status: 404);
    return _json(result.rows.first.assoc());
  });

  router.post('/patients', (Request request) async {
    final b = await _body(request);
    final result = await pool.execute(
      '''INSERT INTO patients
         (first_name, last_name, document_id, phone, email, birth_date, allergies, notes)
         VALUES (:firstName, :lastName, :documentId, :phone, :email, :birthDate, :allergies, :notes)''',
      {
        'firstName': b['first_name'],
        'lastName': b['last_name'],
        'documentId': b['document_id'],
        'phone': b['phone'],
        'email': b['email'],
        'birthDate': b['birth_date'],
        'allergies': b['allergies'],
        'notes': b['notes'],
      },
    );
    return _json({'id': result.lastInsertID.toInt()}, status: 201);
  });

  router.put('/patients/<id>', (Request request, String id) async {
    final b = await _body(request);
    await pool.execute(
      '''UPDATE patients SET
         first_name = :firstName, last_name = :lastName, document_id = :documentId,
         phone = :phone, email = :email, birth_date = :birthDate,
         allergies = :allergies, notes = :notes
         WHERE id = :id''',
      {
        'firstName': b['first_name'],
        'lastName': b['last_name'],
        'documentId': b['document_id'],
        'phone': b['phone'],
        'email': b['email'],
        'birthDate': b['birth_date'],
        'allergies': b['allergies'],
        'notes': b['notes'],
        'id': id,
      },
    );
    return _json({'ok': true});
  });

  router.delete('/patients/<id>', (Request request, String id) async {
    await pool.execute('DELETE FROM patients WHERE id = :id', {'id': id});
    return _json({'ok': true});
  });

  // ---------- Historia clinica ----------
  router.get('/clinical-records', (Request request) async {
    final patientId = request.url.queryParameters['patientId'];
    final result = await pool.execute(
      '''SELECT * FROM clinical_records WHERE patient_id = :patientId
         ORDER BY record_date DESC, id DESC''',
      {'patientId': patientId},
    );
    return _json(_rows(result));
  });

  router.post('/clinical-records', (Request request) async {
    final b = await _body(request);
    final result = await pool.execute(
      '''INSERT INTO clinical_records
         (patient_id, record_date, diagnosis, treatment, observations)
         VALUES (:patientId, :recordDate, :diagnosis, :treatment, :observations)''',
      {
        'patientId': b['patient_id'],
        'recordDate': b['record_date'],
        'diagnosis': b['diagnosis'],
        'treatment': b['treatment'],
        'observations': b['observations'],
      },
    );
    return _json({'id': result.lastInsertID.toInt()}, status: 201);
  });

  router.delete('/clinical-records/<id>', (Request request, String id) async {
    await pool
        .execute('DELETE FROM clinical_records WHERE id = :id', {'id': id});
    return _json({'ok': true});
  });

  // ---------- Citas ----------
  router.get('/appointments', (Request request) async {
    final date = request.url.queryParameters['date'];
    final result = await pool.execute(
      '''SELECT a.*, CONCAT(p.first_name, ' ', p.last_name) AS patient_name
         FROM appointments a
         JOIN patients p ON p.id = a.patient_id
         WHERE DATE(a.date_time) = :day
         ORDER BY a.date_time''',
      {'day': date},
    );
    return _json(_rows(result));
  });

  router.post('/appointments', (Request request) async {
    final b = await _body(request);
    final result = await pool.execute(
      '''INSERT INTO appointments (patient_id, date_time, reason, status)
         VALUES (:patientId, :dateTime, :reason, :status)''',
      {
        'patientId': b['patient_id'],
        'dateTime': b['date_time'],
        'reason': b['reason'],
        'status': b['status'] ?? 'pendiente',
      },
    );
    return _json({'id': result.lastInsertID.toInt()}, status: 201);
  });

  router.patch('/appointments/<id>/status', (Request request, String id) async {
    final b = await _body(request);
    await pool.execute(
      'UPDATE appointments SET status = :status WHERE id = :id',
      {'status': b['status'], 'id': id},
    );
    return _json({'ok': true});
  });

  router.delete('/appointments/<id>', (Request request, String id) async {
    await pool.execute('DELETE FROM appointments WHERE id = :id', {'id': id});
    return _json({'ok': true});
  });

  // ---------- Reportes ----------
  router.get('/reports/appointments', (Request request) async {
    final from = request.url.queryParameters['from'];
    final to = request.url.queryParameters['to'];
    final result = await pool.execute(
      '''SELECT a.date_time, a.reason, a.status,
                CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
                p.document_id
         FROM appointments a
         JOIN patients p ON p.id = a.patient_id
         WHERE DATE(a.date_time) BETWEEN :fromDay AND :toDay
         ORDER BY a.date_time''',
      {'fromDay': from, 'toDay': to},
    );
    return _json(_rows(result));
  });

  router.get('/reports/dashboard', (Request request) async {
    final result = await pool.execute('''
      SELECT
        (SELECT COUNT(*) FROM patients) AS total_patients,
        (SELECT COUNT(*) FROM appointments WHERE DATE(date_time) = CURDATE()) AS today_appointments,
        (SELECT COUNT(*) FROM appointments WHERE status = 'pendiente') AS pending_appointments
    ''');
    return _json(result.rows.first.assoc());
  });

  return router;
}

Future<void> main() async {
  pool = MySQLConnectionPool(
    host: dbHost,
    port: dbPort,
    userName: dbUser,
    password: dbPassword,
    databaseName: dbName,
    maxConnections: 5,
  );
  await pool.execute('SELECT 1');
  print('Conectado a MySQL ($dbHost:$dbPort/$dbName)');

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_cors())
      .addMiddleware(_auth())
      .addHandler(_buildRouter().call);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, serverPort);
  print('API escuchando en http://${server.address.host}:${server.port}');
}
