import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/session.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

/// Layout principal de escritorio: menu lateral fijo + contenido.
class MainLayout extends StatelessWidget {
  const MainLayout({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    (route: '/dashboard', icon: Icons.dashboard_outlined, label: 'Dashboard'),
    (route: '/patients', icon: Icons.people_outline, label: 'Pacientes'),
    (route: '/appointments', icon: Icons.calendar_month_outlined, label: 'Citas'),
    (route: '/treatments', icon: Icons.medical_services_outlined, label: 'Tratamientos'),
    (route: '/billing', icon: Icons.receipt_long_outlined, label: 'Facturacion'),
    (route: '/reports', icon: Icons.bar_chart_outlined, label: 'Reportes'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index =
        _destinations.indexWhere((d) => location.startsWith(d.route));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            minExtendedWidth: 200,
            selectedIndex: _currentIndex(context),
            onDestinationSelected: (index) =>
                context.go(_destinations[index].route),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.local_hospital, size: 40),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Session.fullName ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await AuthRepository().logout();
                          if (context.mounted) context.go('/login');
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Cerrar sesion'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
