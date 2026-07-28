import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Estado clinico de una pieza dental en el odontograma.
enum ToothStatus {
  sano('sano', 'Sano', Colors.white),
  caries('caries', 'Caries', Color(0xFFE53935)),
  obturado('obturado', 'Obturado', Color(0xFF1E88E5)),
  endodoncia('endodoncia', 'Endodoncia', Color(0xFF8E24AA)),
  corona('corona', 'Corona', Color(0xFFD9A521)),
  implante('implante', 'Implante', Color(0xFF00897B)),
  fractura('fractura', 'Fractura', Color(0xFFF4511E)),
  extraido('extraido', 'Extraido / Ausente', Color(0xFF616161));

  const ToothStatus(this.dbValue, this.label, this.color);

  final String dbValue;
  final String label;
  final Color color;

  static ToothStatus fromDb(String? value) => ToothStatus.values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => ToothStatus.sano,
      );
}

/// Estado guardado de una pieza (notacion FDI) de un paciente.
class ToothState extends Equatable {
  const ToothState({
    required this.patientId,
    required this.tooth,
    required this.status,
    this.note,
    this.updatedAt,
  });

  final int patientId;
  final String tooth; // FDI: 11-18, 21-28, 31-38, 41-48
  final ToothStatus status;
  final String? note;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [patientId, tooth, status, note];
}

/// Un cambio registrado en el odontograma.
class ToothChange {
  const ToothChange({
    required this.tooth,
    required this.previousStatus,
    required this.status,
    this.note,
    this.userName,
    required this.changedAt,
  });

  final String tooth;
  final ToothStatus previousStatus;
  final ToothStatus status;
  final String? note;
  final String? userName;
  final DateTime changedAt;
}

/// Orden de las piezas para dibujar el odontograma (adulto, FDI).
const List<String> kUpperTeeth = [
  '18', '17', '16', '15', '14', '13', '12', '11',
  '21', '22', '23', '24', '25', '26', '27', '28',
];
const List<String> kLowerTeeth = [
  '48', '47', '46', '45', '44', '43', '42', '41',
  '31', '32', '33', '34', '35', '36', '37', '38',
];
