import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dental_clinic/core/widgets/placeholder_page.dart';

void main() {
  testWidgets('PlaceholderPage muestra el titulo del modulo', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PlaceholderPage(
          title: 'Tratamientos',
          icon: Icons.medical_services_outlined,
        ),
      ),
    ));

    expect(find.text('Tratamientos'), findsOneWidget);
    expect(find.text('Modulo en construccion'), findsOneWidget);
  });
}
