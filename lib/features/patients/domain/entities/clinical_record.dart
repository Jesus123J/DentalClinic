import 'package:equatable/equatable.dart';

/// Entrada de la historia clinica odontologica de un paciente.
class ClinicalRecord extends Equatable {
  const ClinicalRecord({
    this.id,
    required this.patientId,
    required this.recordDate,
    required this.diagnosis,
    this.tooth,
    this.procedureType,
    this.chiefComplaint,
    this.clinicalExam,
    this.treatment,
    this.prescription,
    this.observations,
  });

  final int? id;
  final int patientId;
  final DateTime recordDate;
  final String diagnosis;

  /// Pieza(s) dental(es) en notacion FDI, ej. "16" o "16, 24".
  final String? tooth;

  /// Tipo de procedimiento: consulta, restauracion, endodoncia, etc.
  final String? procedureType;

  /// Motivo de consulta relatado por el paciente.
  final String? chiefComplaint;

  /// Examen clinico / hallazgos.
  final String? clinicalExam;

  final String? treatment;

  /// Receta o indicaciones.
  final String? prescription;

  final String? observations;

  @override
  List<Object?> get props =>
      [id, patientId, recordDate, diagnosis, tooth, procedureType];
}

/// Tipos de procedimiento odontologico disponibles en el formulario.
const List<String> kProcedureTypes = [
  'Consulta / Evaluacion',
  'Profilaxis (limpieza)',
  'Restauracion (obturacion)',
  'Endodoncia',
  'Extraccion',
  'Corona / Protesis',
  'Implante',
  'Ortodoncia',
  'Radiografia',
  'Blanqueamiento',
  'Otro',
];
