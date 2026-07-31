import '../../../../core/api/api_client.dart';
import '../../domain/entities/tooth_state.dart';

/// Estado del odontograma por paciente (NTS 150-MINSA-2019).
class OdontogramRepository {
  OdontogramRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  /// Clave interna de un hallazgo: "pieza|cara".
  static String key(String tooth, ToothSurface surface) =>
      '$tooth|${surface.dbValue}';

  Future<Map<String, ToothState>> getByPatient(int patientId) async {
    final data =
        await _api.get('/odontogram', {'patientId': '$patientId'}) as List;
    final map = <String, ToothState>{};
    for (final e in data) {
      final json = e as Map<String, dynamic>;
      final state = ToothState(
        patientId: patientId,
        tooth: json['tooth'] ?? '',
        surface: ToothSurface.fromDb(json['surface']),
        status: ToothStatus.fromDb(json['status']),
        note: json['note'],
        updatedAt: DateTime.tryParse(json['updated_at'] ?? ''),
      );
      map[key(state.tooth, state.surface)] = state;
    }
    return map;
  }

  /// Guarda el estado de una pieza o cara ("sano" la restablece).
  Future<void> save(ToothState state) async {
    await _api.put('/odontogram', {
      'patient_id': state.patientId,
      'tooth': state.tooth,
      'surface': state.surface.dbValue,
      'dentition': state.isDeciduous ? 'decidua' : 'permanente',
      'status': state.status.dbValue,
      'note': state.note,
    });
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
        surface: ToothSurface.fromDb(j['surface']),
        previousStatus: ToothStatus.fromDb(j['previous_status']),
        status: ToothStatus.fromDb(j['status']),
        note: j['note'],
        userName: j['user_name'],
        changedAt: DateTime.tryParse(j['changed_at'] ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  Future<OdontogramNotes> notes(int patientId) async {
    final j = await _api.get('/odontogram/notes', {'patientId': '$patientId'})
        as Map<String, dynamic>;
    return OdontogramNotes(
      specifications: j['specifications'],
      observations: j['observations'],
    );
  }

  Future<void> saveNotes(int patientId, OdontogramNotes notes) async {
    await _api.put('/odontogram/notes', {
      'patient_id': patientId,
      'specifications': notes.specifications,
      'observations': notes.observations,
    });
  }
}
