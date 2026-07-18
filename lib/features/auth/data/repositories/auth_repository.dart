import '../../../../core/api/api_client.dart';
import '../../../../core/auth/session.dart';

class AuthRepository {
  AuthRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  /// Inicia sesion y guarda el token en [Session].
  /// Lanza una excepcion si las credenciales son invalidas.
  Future<void> login(String username, String password) async {
    final data = await _api.post('/auth/login', {
      'username': username,
      'password': password,
    }) as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    Session.set(
      newToken: data['token'],
      newUsername: user['username'] ?? '',
      newFullName: user['full_name'] ?? '',
      newRole: user['role'] ?? '',
    );
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', {});
    } finally {
      Session.clear();
    }
  }
}
