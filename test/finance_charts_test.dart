import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:dental_clinic/features/finance/domain/entities/finance_models.dart';
import 'package:dental_clinic/features/finance/presentation/widgets/charts.dart';

/// Datos equivalentes a los que devuelve la API en el periodo de prueba.
const _series = [
  MonthPoint(month: '2026-02', income: 4450, expenses: 326),
  MonthPoint(month: '2026-03', income: 4280, expenses: 1337),
  MonthPoint(month: '2026-04', income: 3980, expenses: 437),
  MonthPoint(month: '2026-05', income: 3500, expenses: 1354),
  MonthPoint(month: '2026-06', income: 6360, expenses: 881),
  MonthPoint(month: '2026-07', income: 6300, expenses: 997),
];

const _top = [
  TopTreatment(name: 'Corona de porcelana', qty: 3, amount: 1350),
  TopTreatment(name: 'Blanqueamiento dental', qty: 3, amount: 900),
  TopTreatment(name: 'Endodoncia', qty: 3, amount: 750),
  TopTreatment(name: 'Ortodoncia - control mensual', qty: 6, amount: 480),
];

Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  setUpAll(() async => initializeDateFormatting('es_PE'));

  for (final size in const [Size(1400, 900), Size(1000, 800), Size(600, 800)]) {
    testWidgets('Grafica ingresos vs gastos sin overflow en ${size.width.toInt()}px',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const IncomeExpenseChart(series: _series)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Ingresos'), findsOneWidget); // leyenda presente
      expect(find.text('Gastos'), findsOneWidget);
      expect(find.text('Feb'), findsOneWidget); // etiquetas del eje
      expect(find.text('Jul'), findsOneWidget);
    });

    testWidgets('Ranking de servicios sin overflow en ${size.width.toInt()}px',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const TopTreatmentsChart(items: _top)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Corona de porcelana'), findsOneWidget);
    });
  }

  testWidgets('Las graficas tambien renderizan en modo oscuro', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(
      const Column(children: [
        IncomeExpenseChart(series: _series),
        SizedBox(height: 16),
        TopTreatmentsChart(items: _top),
      ]),
      brightness: Brightness.dark,
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Estado vacio: sin datos no revienta', (tester) async {
    await tester.pumpWidget(_wrap(const Column(children: [
      IncomeExpenseChart(series: []),
      TopTreatmentsChart(items: []),
    ])));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sin datos en el periodo.'), findsOneWidget);
    expect(find.text('Aun no hay servicios cobrados.'), findsOneWidget);
  });

  testWidgets('El indicador muestra el monto formateado', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox(
      width: 260,
      child: StatTile(
        label: 'Ingresos del periodo',
        value: 'S/ 28,870.00',
        icon: Icons.trending_up,
        color: Color(0xFF2A78D6),
        hint: '101 cobros',
      ),
    )));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('S/ 28,870.00'), findsOneWidget);
    expect(find.text('101 cobros'), findsOneWidget);
  });
}
