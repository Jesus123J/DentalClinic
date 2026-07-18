import '../../../../core/api/api_client.dart';

/// Fila del reporte de atenciones por rango de fechas.
class PatientReportRow {
  const PatientReportRow({
    required this.dateTime,
    required this.patientName,
    required this.documentId,
    required this.reason,
    required this.status,
  });

  final DateTime dateTime;
  final String patientName;
  final String documentId;
  final String reason;
  final String status;
}

class ReportRepository {
  ReportRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  /// Citas/atenciones de pacientes entre dos fechas (inclusive).
  Future<List<PatientReportRow>> appointmentsByRange(
      DateTime from, DateTime to) async {
    final data = await _api.get('/reports/appointments', {
      'from': from.toIso8601String().substring(0, 10),
      'to': to.toIso8601String().substring(0, 10),
    }) as List;
    return data
        .map((e) => e as Map<String, dynamic>)
        .map((json) => PatientReportRow(
              dateTime:
                  DateTime.tryParse(json['date_time'] ?? '') ?? DateTime.now(),
              patientName: json['patient_name'] ?? '',
              documentId: json['document_id'] ?? '-',
              reason: json['reason'] ?? '-',
              status: json['status'] ?? '-',
            ))
        .toList();
  }

  /// Indicadores para el dashboard.
  Future<({int totalPatients, int todayAppointments, int pendingAppointments})>
      dashboardStats() async {
    final json = await _api.get('/reports/dashboard') as Map<String, dynamic>;
    int parse(String key) => int.parse(json[key].toString());
    return (
      totalPatients: parse('total_patients'),
      todayAppointments: parse('today_appointments'),
      pendingAppointments: parse('pending_appointments'),
    );
  }
}
