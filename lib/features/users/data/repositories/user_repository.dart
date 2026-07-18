import '../../../../core/api/api_client.dart';
import '../../domain/entities/app_user.dart';

class UserRepository {
  UserRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  AppUser _fromJson(Map<String, dynamic> json) => AppUser(
        id: int.parse(json['id'].toString()),
        username: json['username'] ?? '',
        fullName: json['full_name'] ?? '',
        role: json['role'] ?? '',
        active: json['active'].toString() == '1',
      );

  Future<List<AppUser>> getAll() async {
    final data = await _api.get('/users') as List;
    return data.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create({
    required String username,
    required String password,
    required String fullName,
    required String role,
  }) async {
    await _api.post('/users', {
      'username': username,
      'password': password,
      'full_name': fullName,
      'role': role,
    });
  }

  Future<void> setActive(int id, bool active) async {
    await _api.patch('/users/$id/active', {'active': active});
  }
}
