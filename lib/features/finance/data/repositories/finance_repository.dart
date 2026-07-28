import '../../../../core/api/api_client.dart';
import '../../domain/entities/finance_models.dart';

/// Acceso a catalogo, cobros, gastos y resumen financiero.
class FinanceRepository {
  FinanceRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  static double _num(dynamic v) =>
      v == null ? 0 : double.tryParse(v.toString()) ?? 0;

  Map<String, String> _range(DateTime from, DateTime to) => {
        'from': from.toIso8601String().substring(0, 10),
        'to': to.toIso8601String().substring(0, 10),
      };

  // ---------- Catalogo ----------
  Future<List<Treatment>> treatments() async {
    final data = await _api.get('/treatments') as List;
    return data.map((e) {
      final j = e as Map<String, dynamic>;
      return Treatment(
        id: int.parse(j['id'].toString()),
        name: j['name'] ?? '',
        description: j['description'],
        price: _num(j['price']),
      );
    }).toList();
  }

  Future<void> saveTreatment(Treatment t) async {
    final body = {
      'name': t.name,
      'description': t.description,
      'price': t.price,
    };
    if (t.id == null) {
      await _api.post('/treatments', body);
    } else {
      await _api.put('/treatments/${t.id}', body);
    }
  }

  Future<void> deleteTreatment(int id) async {
    await _api.delete('/treatments/$id');
  }

  // ---------- Cobros ----------
  Future<List<Sale>> sales(DateTime from, DateTime to) async {
    final data = await _api.get('/sales', _range(from, to)) as List;
    return data.map((e) {
      final j = e as Map<String, dynamic>;
      return Sale(
        id: int.parse(j['id'].toString()),
        patientId: j['patient_id'] == null
            ? null
            : int.tryParse(j['patient_id'].toString()),
        patientName: j['patient_name'],
        total: _num(j['total']),
        paid: _num(j['paid']),
        method: PaymentMethod.fromDb(j['method']),
        status: j['status'] ?? 'pagado',
        note: j['note'],
        createdAt:
            DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  Future<Sale> saleDetail(int id) async {
    final j = await _api.get('/sales/$id') as Map<String, dynamic>;
    final items = (j['items'] as List? ?? []).map((e) {
      final i = e as Map<String, dynamic>;
      return SaleItem(
        treatmentId: i['treatment_id'] == null
            ? null
            : int.tryParse(i['treatment_id'].toString()),
        name: i['name'] ?? '',
        price: _num(i['price']),
        qty: int.tryParse(i['qty'].toString()) ?? 1,
      );
    }).toList();
    return Sale(
      id: int.parse(j['id'].toString()),
      patientId: j['patient_id'] == null
          ? null
          : int.tryParse(j['patient_id'].toString()),
      patientName: j['patient_name'],
      total: _num(j['total']),
      paid: _num(j['paid']),
      method: PaymentMethod.fromDb(j['method']),
      status: j['status'] ?? 'pagado',
      note: j['note'],
      createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      items: items,
    );
  }

  Future<int> createSale({
    int? patientId,
    required List<SaleItem> items,
    required PaymentMethod method,
    required String status,
    double? paid,
    String? note,
  }) async {
    final total = items.fold<double>(0, (s, i) => s + i.subtotal);
    final data = await _api.post('/sales', {
      'patient_id': patientId,
      'method': method.dbValue,
      'status': status,
      'paid': paid ?? (status == 'pagado' ? total : 0),
      'note': note,
      'items': [
        for (final i in items)
          {
            'treatment_id': i.treatmentId,
            'name': i.name,
            'price': i.price,
            'qty': i.qty,
          },
      ],
    });
    return int.parse(data['id'].toString());
  }

  /// Registra un pago del cobro. Sin [amount] salda todo lo pendiente.
  Future<void> registerPayment(int id,
      {double? amount, PaymentMethod? method}) async {
    await _api.patch('/sales/$id/payment', {
      'amount': ?amount,
      'method': ?method?.dbValue,
    });
  }

  Future<void> voidSale(int id) async {
    await _api.delete('/sales/$id');
  }

  // ---------- Gastos ----------
  Future<List<Expense>> expenses(DateTime from, DateTime to) async {
    final data = await _api.get('/expenses', _range(from, to)) as List;
    return data.map((e) {
      final j = e as Map<String, dynamic>;
      return Expense(
        id: int.parse(j['id'].toString()),
        concept: j['concept'] ?? '',
        category: j['category'] ?? 'General',
        amount: _num(j['amount']),
        spentAt: DateTime.tryParse(j['spent_at'] ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  Future<void> createExpense(Expense e) async {
    await _api.post('/expenses', {
      'concept': e.concept,
      'category': e.category,
      'amount': e.amount,
      'spent_at': e.spentAt.toIso8601String().substring(0, 10),
    });
  }

  Future<void> deleteExpense(int id) async {
    await _api.delete('/expenses/$id');
  }

  // ---------- Resumen ----------
  Future<FinanceSummary> summary(DateTime from, DateTime to) async {
    final j =
        await _api.get('/finance/summary', _range(from, to)) as Map<String, dynamic>;
    return FinanceSummary(
      income: _num(j['income']),
      expenses: _num(j['expenses']),
      profit: _num(j['profit']),
      today: _num(j['today']),
      pending: _num(j['pending']),
      salesCount: int.tryParse(j['sales_count'].toString()) ?? 0,
      series: (j['series'] as List? ?? []).map((e) {
        final s = e as Map<String, dynamic>;
        return MonthPoint(
          month: s['month'] ?? '',
          income: _num(s['income']),
          expenses: _num(s['expenses']),
        );
      }).toList(),
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
