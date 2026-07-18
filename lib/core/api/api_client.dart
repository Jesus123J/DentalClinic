import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/session.dart';

/// Cliente HTTP hacia la API REST (server/bin/server.dart).
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Direccion del servidor API. Cambiar si el servidor corre en otra maquina.
  static const String baseUrl = 'http://localhost:8090';

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

  Future<void> delete(String path) async =>
      _decode(await http.delete(_uri(path), headers: _headers));
}
