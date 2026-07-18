import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dental_clinic/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('La pagina de login muestra el formulario', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('Clinica Dental'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Contrasena'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
