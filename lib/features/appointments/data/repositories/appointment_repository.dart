import '../../../../core/api/api_client.dart';
import '../../domain/entities/appointment.dart';

class AppointmentRepository {
  AppointmentRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Appointment _fromJson(Map<String, dynamic> json) => Appointment(
        id: int.parse(json['id'].toString()),
        patientId: int.parse(json['patient_id'].toString()),
        patientName: json['patient_name'] ?? '',
        dateTime: DateTime.tryParse(json['date_time'] ?? '') ?? DateTime.now(),
        reason: json['reason'],
        status: AppointmentStatus.fromDb(json['status']),
      );

  /// Citas de un dia especifico.
  Future<List<Appointment>> getByDate(DateTime date) async {
    final day = date.toIso8601String().substring(0, 10);
    final data = await _api.get('/appointments', {'date': day}) as List;
    return data.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create(Appointment appointment) async {
    await _api.post('/appointments', {
      'patient_id': appointment.patientId,
      'date_time': _formatDateTime(appointment.dateTime),
      'reason': appointment.reason,
      'status': appointment.status.dbValue,
    });
  }

  Future<void> updateStatus(int id, AppointmentStatus status) async {
    await _api.patch('/appointments/$id/status', {'status': status.dbValue});
  }

  Future<void> delete(int id) async {
    await _api.delete('/appointments/$id');
  }

  String _formatDateTime(DateTime dt) =>
      dt.toIso8601String().substring(0, 19).replaceFirst('T', ' ');
}
