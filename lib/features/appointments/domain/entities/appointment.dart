import 'package:equatable/equatable.dart';

enum AppointmentStatus {
  pendiente('pendiente', 'Pendiente'),
  atendida('atendida', 'Atendida'),
  cancelada('cancelada', 'Cancelada');

  const AppointmentStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static AppointmentStatus fromDb(String? value) =>
      AppointmentStatus.values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => AppointmentStatus.pendiente,
      );
}

/// Cita odontologica.
class Appointment extends Equatable {
  const Appointment({
    this.id,
    required this.patientId,
    this.patientName = '',
    required this.dateTime,
    this.reason,
    this.status = AppointmentStatus.pendiente,
  });

  final int? id;
  final int patientId;
  final String patientName; // viene del JOIN con patients
  final DateTime dateTime;
  final String? reason;
  final AppointmentStatus status;

  @override
  List<Object?> get props => [id, patientId, dateTime, reason, status];
}
