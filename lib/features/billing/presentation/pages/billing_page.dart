import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_page.dart';

class BillingPage extends StatelessWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Facturacion',
      icon: Icons.receipt_long_outlined,
    );
  }
}
