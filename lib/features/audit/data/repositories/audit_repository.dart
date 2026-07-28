import '../../../../core/api/api_client.dart';
import '../../domain/entities/audit_entry.dart';

class AuditRepository {
  AuditRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  /// Bitacora de operaciones (quien, que, cuando y por que).
  Future<List<AuditEntry>> entries({
    DateTime? from,
    DateTime? to,
    String? entity,
    String? user,
  }) async {
    final data = await _api.get('/audit', {
      'from': ?from?.toIso8601String().substring(0, 10),
      'to': ?to?.toIso8601String().substring(0, 10),
      'entity': ?entity,
      'user': ?user,
    }) as List;
    return data.map((e) {
      final j = e as Map<String, dynamic>;
      return AuditEntry(
        id: int.parse(j['id'].toString()),
        userName: j['user_name'] ?? 'Sistema',
        userRole: j['user_role'] ?? '',
        action: j['action'] ?? '',
        entity: j['entity'] ?? '',
        entityId: j['entity_id'] == null
            ? null
            : int.tryParse(j['entity_id'].toString()),
        description: j['description'],
        reason: j['reason'],
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  /// Registros dados de baja (solo el ingeniero de sistemas).
  Future<List<TrashEntry>> trash() async {
    final data = await _api.get('/trash') as List;
    return data.map((e) {
      final j = e as Map<String, dynamic>;
      return TrashEntry(
        id: int.parse(j['id'].toString()),
        table: j['table'] ?? '',
        entity: j['entity'] ?? '',
        label: j['label']?.toString() ?? '',
        deactivatedAt: DateTime.tryParse(j['deactivated_at'] ?? ''),
        deactivatedBy: j['deactivated_by'],
        reason: j['deactivate_reason'],
      );
    }).toList();
  }

  Future<void> restore(TrashEntry entry, String reason) async {
    await _api.post('/trash/${entry.table}/${entry.id}/restore',
        {'reason': reason});
  }
}
