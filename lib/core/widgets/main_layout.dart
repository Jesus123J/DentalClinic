import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/session.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

/// Layout principal responsive:
/// - Ancho >= 1100: menu lateral extendido (icono + texto).
/// - Entre 800 y 1100: menu lateral compacto (solo iconos).
/// - Menor a 800: barra superior con menu hamburguesa (Drawer).
class MainLayout extends StatelessWidget {
  const MainLayout({super.key, required this.child});

  final Widget child;

  /// La pestana Usuarios solo aparece para el administrador.
  static List<({String route, IconData icon, String label})>
      get _destinations => [
            (route: '/dashboard', icon: Icons.dashboard_outlined, label: 'Dashboard'),
            (route: '/patients', icon: Icons.people_outline, label: 'Pacientes'),
            (route: '/appointments', icon: Icons.calendar_month_outlined, label: 'Citas'),
            (route: '/reports', icon: Icons.bar_chart_outlined, label: 'Reportes'),
            if (Session.role == 'admin')
              (route: '/users', icon: Icons.manage_accounts_outlined, label: 'Usuarios'),
          ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index =
        _destinations.indexWhere((d) => location.startsWith(d.route));
    return index < 0 ? 0 : index;
  }

  Future<void> _logout(BuildContext context) async {
    await AuthRepository().logout();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < 800) return _buildMobile(context);
        return _buildDesktop(context, extended: width >= 1100);
      },
    );
  }

  // ---------- Escritorio / pantalla ancha ----------
  Widget _buildDesktop(BuildContext context, {required bool extended}) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            minExtendedWidth: 200,
            labelType: extended ? null : NavigationRailLabelType.all,
            selectedIndex: _currentIndex(context),
            onDestinationSelected: (index) =>
                context.go(_destinations[index].route),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.local_hospital, size: 40),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: extended
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Session.fullName ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                            TextButton.icon(
                              onPressed: () => _logout(context),
                              icon: const Icon(Icons.logout, size: 18),
                              label: const Text('Cerrar sesion'),
                            ),
                          ],
                        )
                      : IconButton(
                          tooltip: 'Cerrar sesion (${Session.fullName ?? ''})',
                          onPressed: () => _logout(context),
                          icon: const Icon(Icons.logout),
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

  // ---------- Pantalla angosta: hamburguesa + Drawer ----------
  Widget _buildMobile(BuildContext context) {
    final current = _destinations[_currentIndex(context)];
    return Scaffold(
      appBar: AppBar(title: Text(current.label)),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.local_hospital, size: 40),
                  const SizedBox(height: 8),
                  Text('Clinica Dental',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(Session.fullName ?? '',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            for (final d in _destinations)
              ListTile(
                leading: Icon(d.icon),
                title: Text(d.label),
                selected: d.route == current.route,
                onTap: () {
                  Navigator.pop(context);
                  context.go(d.route);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesion'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}
