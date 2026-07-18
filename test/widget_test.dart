import 'package:flutter_test/flutter_test.dart';

import 'package:dental_clinic/app.dart';

void main() {
  testWidgets('La app arranca y muestra el dashboard', (tester) async {
    await tester.pumpWidget(const DentalClinicApp());
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
  });
}
