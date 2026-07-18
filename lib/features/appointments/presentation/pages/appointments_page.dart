import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_page.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Citas',
      icon: Icons.calendar_month_outlined,
    );
  }
}
