import '../../../../core/api/api_client.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../finance/domain/entities/finance_models.dart';
import '../../domain/entities/patient.dart';
import '../../domain/entities/patient_summary.dart';
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
  Future<void> delete(int id, {String? reason}) async {
    await _api.delete('/patients/$id', reason: reason);
  }

  static double _num(dynamic v) =>
      v == null ? 0 : double.tryParse(v.toString()) ?? 0;

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  /// Resumen economico y de visitas del paciente.
  Future<PatientSummary> summary(int id) async {
    final j = await _api.get('/patients/$id/summary') as Map<String, dynamic>;

    final sales = (j['sales'] as List? ?? []).map((e) {
      final s = e as Map<String, dynamic>;
      return Sale(
        id: int.parse(s['id'].toString()),
        patientId: id,
        total: _num(s['total']),
        paid: _num(s['paid']),
        method: PaymentMethod.fromDb(s['method']),
        status: s['status'] ?? 'pagado',
        note: s['note'],
        createdAt: _date(s['created_at']) ?? DateTime.now(),
        items: (s['items'] as List? ?? []).map((i) {
          final it = i as Map<String, dynamic>;
          return SaleItem(
            name: it['name'] ?? '',
            price: _num(it['price']),
            qty: int.tryParse(it['qty'].toString()) ?? 1,
          );
        }).toList(),
      );
    }).toList();

    final appointments = (j['appointments'] as List? ?? []).map((e) {
      final a = e as Map<String, dynamic>;
      return Appointment(
        id: int.parse(a['id'].toString()),
        patientId: id,
        dateTime: _date(a['date_time']) ?? DateTime.now(),
        reason: a['reason'],
        status: AppointmentStatus.fromDb(a['status']),
      );
    }).toList();

    return PatientSummary(
      spent: _num(j['spent']),
      due: _num(j['due']),
      salesCount: int.tryParse(j['sales_count'].toString()) ?? 0,
      visits: int.tryParse(j['visits'].toString()) ?? 0,
      recordsCount: int.tryParse(j['records_count']?.toString() ?? '0') ?? 0,
      firstVisit: _date(j['first_visit']),
      lastVisit: _date(j['last_visit']),
      nextVisit: _date(j['next_visit']),
      sales: sales,
      appointments: appointments,
      topTreatments: (j['top_treatments'] as List? ?? []).map((e) {
        final t = e as Map<String, dynamic>;
        return TopTreatment(
          name: t['name'] ?? '',
          qty: int.tryParse(t['qty'].toString()) ?? 0,
          amount: _num(t['amount']),
        );
      }).toList(),
    );
  }
}
