import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_page.dart';

class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Pacientes',
      icon: Icons.people_outline,
    );
  }
}
