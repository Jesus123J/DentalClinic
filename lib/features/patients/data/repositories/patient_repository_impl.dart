import '../../../../core/api/api_client.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/patient_repository.dart';

class PatientRepositoryImpl implements PatientRepository {
  PatientRepositoryImpl({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Patient _fromJson(Map<String, dynamic> json) => Patient(
        id: int.parse(json['id'].toString()),
        firstName: json['first_name'] ?? '',
        lastName: json['last_name'] ?? '',
        documentId: json['document_id'],
        phone: json['phone'],
        email: json['email'],
        birthDate: json['birth_date'] == null
            ? null
            : DateTime.tryParse(json['birth_date']),
        allergies: json['allergies'],
        notes: json['notes'],
        createdAt:
            DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> _toJson(Patient p) => {
        'first_name': p.firstName,
        'last_name': p.lastName,
        'document_id': p.documentId,
        'phone': p.phone,
        'email': p.email,
        'birth_date': p.birthDate?.toIso8601String().substring(0, 10),
        'allergies': p.allergies,
        'notes': p.notes,
      };

  @override
  Future<List<Patient>> getAll({String? search}) async {
    final query = (search == null || search.trim().isEmpty)
        ? null
        : {'q': search.trim()};
    final data = await _api.get('/patients', query) as List;
    return data.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Patient?> getById(int id) async {
    final data = await _api.get('/patients/$id');
    return _fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Patient> create(Patient patient) async {
    final data = await _api.post('/patients', _toJson(patient));
    return (await getById(int.parse(data['id'].toString())))!;
  }

  @override
  Future<void> update(Patient patient) async {
    await _api.put('/patients/${patient.id}', _toJson(patient));
  }

  @override
  Future<void> delete(int id) async {
    await _api.delete('/patients/$id');
  }
}
