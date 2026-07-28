import '../../../appointments/domain/entities/appointment.dart';
import '../../../finance/domain/entities/finance_models.dart';

/// Resumen economico y de visitas de un paciente.
class PatientSummary {
  const PatientSummary({
    required this.spent,
    required this.due,
    required this.salesCount,
    required this.visits,
    required this.recordsCount,
    this.firstVisit,
    this.lastVisit,
    this.nextVisit,
    this.sales = const [],
    this.appointments = const [],
    this.topTreatments = const [],
  });

  /// Total cobrado al paciente (sin contar anulados).
  final double spent;

  /// Saldo pendiente de pago.
  final double due;

  final int salesCount;

  /// Citas efectivamente atendidas.
  final int visits;

  final int recordsCount;
  final DateTime? firstVisit;
  final DateTime? lastVisit;
  final DateTime? nextVisit;

  final List<Sale> sales;
  final List<Appointment> appointments;
  final List<TopTreatment> topTreatments;
}
