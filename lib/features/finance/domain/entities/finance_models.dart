import 'package:equatable/equatable.dart';

/// Servicio del catalogo con su precio.
class Treatment extends Equatable {
  const Treatment({
    this.id,
    required this.name,
    this.description,
    required this.price,
  });

  final int? id;
  final String name;
  final String? description;
  final double price;

  @override
  List<Object?> get props => [id, name, price];
}

/// Linea de un cobro (servicio + cantidad).
class SaleItem extends Equatable {
  const SaleItem({
    this.treatmentId,
    required this.name,
    required this.price,
    this.qty = 1,
  });

  final int? treatmentId;
  final String name;
  final double price;
  final int qty;

  double get subtotal => price * qty;

  SaleItem copyWith({int? qty}) => SaleItem(
        treatmentId: treatmentId,
        name: name,
        price: price,
        qty: qty ?? this.qty,
      );

  @override
  List<Object?> get props => [treatmentId, name, price, qty];
}

enum PaymentMethod {
  efectivo('efectivo', 'Efectivo'),
  tarjeta('tarjeta', 'Tarjeta'),
  yape('yape', 'Yape'),
  plin('plin', 'Plin'),
  transferencia('transferencia', 'Transferencia'),
  otro('otro', 'Otro');

  const PaymentMethod(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static PaymentMethod fromDb(String? v) => PaymentMethod.values
      .firstWhere((m) => m.dbValue == v, orElse: () => PaymentMethod.efectivo);
}

/// Cobro registrado.
class Sale extends Equatable {
  const Sale({
    required this.id,
    this.patientId,
    this.patientName,
    required this.total,
    required this.paid,
    required this.method,
    required this.status,
    this.note,
    required this.createdAt,
    this.items = const [],
  });

  final int id;
  final int? patientId;
  final String? patientName;
  final double total;
  final double paid;
  final PaymentMethod method;
  final String status; // pagado, pendiente, anulado
  final String? note;
  final DateTime createdAt;
  final List<SaleItem> items;

  double get due => total - paid;

  @override
  List<Object?> get props => [id, total, status];
}

/// Gasto del consultorio.
class Expense extends Equatable {
  const Expense({
    this.id,
    required this.concept,
    required this.category,
    required this.amount,
    required this.spentAt,
  });

  final int? id;
  final String concept;
  final String category;
  final double amount;
  final DateTime spentAt;

  @override
  List<Object?> get props => [id, concept, amount, spentAt];
}

const List<String> kExpenseCategories = [
  'General',
  'Materiales',
  'Sueldos',
  'Alquiler',
  'Servicios (luz, agua, internet)',
  'Equipos',
  'Marketing',
  'Impuestos',
];

/// Punto de la serie mensual ingresos vs gastos.
class MonthPoint {
  const MonthPoint({
    required this.month,
    required this.income,
    required this.expenses,
  });

  final String month; // yyyy-MM
  final double income;
  final double expenses;
}

/// Tratamiento en el ranking de mas vendidos.
class TopTreatment {
  const TopTreatment({
    required this.name,
    required this.qty,
    required this.amount,
  });

  final String name;
  final int qty;
  final double amount;
}

/// Resumen financiero de un rango.
class FinanceSummary {
  const FinanceSummary({
    required this.income,
    required this.expenses,
    required this.profit,
    required this.today,
    required this.pending,
    required this.salesCount,
    required this.series,
    required this.topTreatments,
  });

  final double income;
  final double expenses;
  final double profit;
  final double today;
  final double pending;
  final int salesCount;
  final List<MonthPoint> series;
  final List<TopTreatment> topTreatments;
}
