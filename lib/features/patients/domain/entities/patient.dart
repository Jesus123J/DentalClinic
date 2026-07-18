import 'package:equatable/equatable.dart';

/// Entidad de dominio: paciente de la clinica.
class Patient extends Equatable {
  const Patient({
    this.id,
    required this.firstName,
    required this.lastName,
    this.documentId,
    this.phone,
    this.email,
    this.birthDate,
    this.allergies,
    this.notes,
    required this.createdAt,
  });

  final int? id;
  final String firstName;
  final String lastName;
  final String? documentId;
  final String? phone;
  final String? email;
  final DateTime? birthDate;
  final String? allergies;
  final String? notes;
  final DateTime createdAt;

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props =>
      [id, firstName, lastName, documentId, phone, email, birthDate];
}
