import 'package:equatable/equatable.dart';

/// Entrada de la historia clinica de un paciente.
class ClinicalRecord extends Equatable {
  const ClinicalRecord({
    this.id,
    required this.patientId,
    required this.recordDate,
    required this.diagnosis,
    this.treatment,
    this.observations,
  });

  final int? id;
  final int patientId;
  final DateTime recordDate;
  final String diagnosis;
  final String? treatment;
  final String? observations;

  @override
  List<Object?> get props => [id, patientId, recordDate, diagnosis];
}
