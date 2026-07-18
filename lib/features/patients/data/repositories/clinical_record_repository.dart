import '../../../../core/api/api_client.dart';
import '../../domain/entities/clinical_record.dart';

/// Historia clinica: registros medicos por paciente.
class ClinicalRecordRepository {
  ClinicalRecordRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  ClinicalRecord _fromJson(Map<String, dynamic> json) => ClinicalRecord(
        id: int.parse(json['id'].toString()),
        patientId: int.parse(json['patient_id'].toString()),
        recordDate:
            DateTime.tryParse(json['record_date'] ?? '') ?? DateTime.now(),
        diagnosis: json['diagnosis'] ?? '',
        treatment: json['treatment'],
        observations: json['observations'],
      );

  Future<List<ClinicalRecord>> getByPatient(int patientId) async {
    final data = await _api
        .get('/clinical-records', {'patientId': '$patientId'}) as List;
    return data.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create(ClinicalRecord record) async {
    await _api.post('/clinical-records', {
      'patient_id': record.patientId,
      'record_date': record.recordDate.toIso8601String().substring(0, 10),
      'diagnosis': record.diagnosis,
      'treatment': record.treatment,
      'observations': record.observations,
    });
  }

  Future<void> delete(int id) async {
    await _api.delete('/clinical-records/$id');
  }
}
