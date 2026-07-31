import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Estado clinico de una pieza o cara dental en el odontograma.
enum ToothStatus {
  sano('sano', 'Sano', Colors.white),
  caries('caries', 'Caries', Color(0xFFE53935)),
  obturado('obturado', 'Obturado', Color(0xFF1E88E5)),
  endodoncia('endodoncia', 'Endodoncia', Color(0xFF8E24AA)),
  corona('corona', 'Corona', Color(0xFFD9A521)),
  implante('implante', 'Implante', Color(0xFF00897B)),
  fractura('fractura', 'Fractura', Color(0xFFF4511E)),
  sellante('sellante', 'Sellante', Color(0xFF43A047)),
  protesis('protesis', 'Protesis / puente', Color(0xFF6D4C41)),
  extraido('extraido', 'Extraido / Ausente', Color(0xFF616161));

  const ToothStatus(this.dbValue, this.label, this.color);

  final String dbValue;
  final String label;
  final Color color;

  /// Estados que aplican a toda la pieza, no a una cara.
  bool get isWholeTooth => const {
        ToothStatus.extraido,
        ToothStatus.implante,
        ToothStatus.corona,
        ToothStatus.protesis,
        ToothStatus.endodoncia,
      }.contains(this);

  static ToothStatus fromDb(String? value) => ToothStatus.values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => ToothStatus.sano,
      );
}

/// Caras de una pieza dental (NTS 150-MINSA-2019).
enum ToothSurface {
  completa('completa', 'Pieza completa'),
  vestibular('V', 'Vestibular'),
  lingual('L', 'Lingual / Palatina'),
  mesial('M', 'Mesial'),
  distal('D', 'Distal'),
  oclusal('O', 'Oclusal / Incisal');

  const ToothSurface(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static ToothSurface fromDb(String? value) => ToothSurface.values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => ToothSurface.completa,
      );
}

/// Estado guardado de una pieza o cara de un paciente.
class ToothState extends Equatable {
  const ToothState({
    required this.patientId,
    required this.tooth,
    this.surface = ToothSurface.completa,
    required this.status,
    this.note,
    this.updatedAt,
  });

  final int patientId;

  /// FDI. Permanente: 11-18, 21-28, 31-38, 41-48.
  /// Decidua: 51-55, 61-65, 71-75, 81-85.
  final String tooth;

  final ToothSurface surface;
  final ToothStatus status;
  final String? note;
  final DateTime? updatedAt;

  bool get isDeciduous {
    final n = int.tryParse(tooth) ?? 0;
    return n >= 51 && n <= 85;
  }

  @override
  List<Object?> get props => [patientId, tooth, surface, status, note];
}

/// Un cambio registrado en el odontograma.
class ToothChange {
  const ToothChange({
    required this.tooth,
    this.surface = ToothSurface.completa,
    required this.previousStatus,
    required this.status,
    this.note,
    this.userName,
    required this.changedAt,
  });

  final String tooth;
  final ToothSurface surface;
  final ToothStatus previousStatus;
  final ToothStatus status;
  final String? note;
  final String? userName;
  final DateTime changedAt;
}

/// Especificaciones y observaciones del pie del odontograma oficial.
class OdontogramNotes {
  const OdontogramNotes({this.specifications, this.observations});

  final String? specifications;
  final String? observations;
}

// ---------- Distribucion de piezas segun el formato oficial ----------

/// Denticion permanente, arcada superior (de derecha a izquierda del paciente).
const List<String> kUpperTeeth = [
  '18', '17', '16', '15', '14', '13', '12', '11',
  '21', '22', '23', '24', '25', '26', '27', '28',
];

/// Denticion permanente, arcada inferior.
const List<String> kLowerTeeth = [
  '48', '47', '46', '45', '44', '43', '42', '41',
  '31', '32', '33', '34', '35', '36', '37', '38',
];

/// Denticion decidua (ninos), arcada superior.
const List<String> kUpperDeciduous = [
  '55', '54', '53', '52', '51', '61', '62', '63', '64', '65',
];

/// Denticion decidua, arcada inferior.
const List<String> kLowerDeciduous = [
  '85', '84', '83', '82', '81', '71', '72', '73', '74', '75',
];
