import '../../../../core/api/api_client.dart';
import '../../domain/entities/tooth_state.dart';

/// Estado del odontograma por paciente.
class OdontogramRepository {
  OdontogramRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Future<Map<String, ToothState>> getByPatient(int patientId) async {
    final data =
        await _api.get('/odontogram', {'patientId': '$patientId'}) as List;
    final map = <String, ToothState>{};
    for (final e in data) {
      final json = e as Map<String, dynamic>;
      final state = ToothState(
        patientId: patientId,
        tooth: json['tooth'] ?? '',
        status: ToothStatus.fromDb(json['status']),
        note: json['note'],
        updatedAt: DateTime.tryParse(json['updated_at'] ?? ''),
      );
      map[state.tooth] = state;
    }
    return map;
  }

  /// Historial de cambios: de todo el paciente o de una pieza concreta.
  Future<List<ToothChange>> history(int patientId, {String? tooth}) async {
    final data = await _api.get('/odontogram/history', {
      'patientId': '$patientId',
      'tooth': ?tooth,
    }) as List;
    return data.map((e) {
      final j = e as Map<String, dynamic>;
      return ToothChange(
        tooth: j['tooth'] ?? '',
        previousStatus: ToothStatus.fromDb(j['previous_status']),
        status: ToothStatus.fromDb(j['status']),
        note: j['note'],
        userName: j['user_name'],
        changedAt: DateTime.tryParse(j['changed_at'] ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  /// Guarda el estado de una pieza ("sano" la restablece).
  Future<void> save(ToothState state) async {
    await _api.put('/odontogram', {
      'patient_id': state.patientId,
      'tooth': state.tooth,
      'status': state.status.dbValue,
      'note': state.note,
    });
  }
}
