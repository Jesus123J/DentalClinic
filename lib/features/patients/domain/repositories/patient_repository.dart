import '../entities/patient.dart';

/// Contrato del repositorio de pacientes (la capa data lo implementa).
abstract class PatientRepository {
  Future<List<Patient>> getAll({String? search});
  Future<Patient?> getById(int id);
  Future<Patient> create(Patient patient);
  Future<void> update(Patient patient);
  Future<void> delete(int id);
}
