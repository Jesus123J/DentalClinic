import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/session.dart';

/// Cliente HTTP hacia la API REST (server/bin/server.dart).
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Direccion del servidor API.
  /// En desarrollo apunta al servidor local; para produccion compilar con:
  /// flutter build web --dart-define=API_URL=https://tudominio.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8090',
  );

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 400) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Map<String, String> get _headers => {
        'content-type': 'application/json',
        if (Session.token != null) 'authorization': 'Bearer ${Session.token}',
      };

  Future<dynamic> get(String path, [Map<String, String>? query]) async =>
      _decode(await http.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, Map<String, dynamic> body) async =>
      _decode(await http.post(_uri(path),
          headers: _headers, body: jsonEncode(body)));

  Future<dynamic> put(String path, Map<String, dynamic> body) async =>
      _decode(await http.put(_uri(path),
          headers: _headers, body: jsonEncode(body)));

  Future<dynamic> patch(String path, Map<String, dynamic> body) async =>
      _decode(await http.patch(_uri(path),
          headers: _headers, body: jsonEncode(body)));

  /// Las bajas son logicas y exigen un motivo, que viaja en el cuerpo.
  Future<void> delete(String path, {String? reason}) async => _decode(
        await http.delete(
          _uri(path),
          headers: _headers,
          body: jsonEncode({'reason': ?reason}),
        ),
      );

  /// Descarga el contenido binario de un recurso (imagenes, PDFs).
  Future<List<int>> getBytes(String path, [Map<String, String>? query]) async {
    final response = await http.get(_uri(path, query), headers: _headers);
    if (response.statusCode >= 400) {
      throw Exception('HTTP ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  /// Sube un archivo como multipart/form-data.
  Future<dynamic> uploadFile(
    String path, {
    required Map<String, String> fields,
    required List<int> bytes,
    required String filename,
    String fileField = 'file',
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    if (Session.token != null) {
      request.headers['authorization'] = 'Bearer ${Session.token}';
    }
    request.fields.addAll(fields);
    request.files
        .add(http.MultipartFile.fromBytes(fileField, bytes, filename: filename));
    final streamed = await request.send();
    return _decode(await http.Response.fromStream(streamed));
  }
}
