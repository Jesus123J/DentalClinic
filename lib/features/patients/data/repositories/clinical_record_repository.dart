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
        tooth: json['tooth'],
        procedureType: json['procedure_type'],
        chiefComplaint: json['chief_complaint'],
        clinicalExam: json['clinical_exam'],
        treatment: json['treatment'],
        prescription: json['prescription'],
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
      'tooth': record.tooth,
      'procedure_type': record.procedureType,
      'chief_complaint': record.chiefComplaint,
      'clinical_exam': record.clinicalExam,
      'treatment': record.treatment,
      'prescription': record.prescription,
      'observations': record.observations,
    });
  }

  Future<void> delete(int id, {String? reason}) async {
    await _api.delete('/clinical-records/$id', reason: reason);
  }
}
