import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/repositories/auth_repository.dart';
import '../auth/session.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Layout principal responsive estilo web app:
/// - Ancho >= 1100: sidebar oscuro extendido con logo y texto.
/// - Entre 800 y 1100: sidebar compacto (solo iconos).
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

  // ---------- Pantalla ancha: sidebar oscuro ----------
  Widget _buildDesktop(BuildContext context, {required bool extended}) {
    final selected = _currentIndex(context);
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: extended ? 240 : 76,
            color: AppTheme.charcoal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                _Brand(extended: extended),
                const SizedBox(height: 28),
                for (var i = 0; i < _destinations.length; i++)
                  _MenuItem(
                    destination: _destinations[i],
                    selected: i == selected,
                    extended: extended,
                    onTap: () => context.go(_destinations[i].route),
                  ),
                const Spacer(),
                const Divider(color: Colors.white12, height: 1),
                _UserFooter(
                  extended: extended,
                  onLogout: () => _logout(context),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  // ---------- Pantalla angosta: hamburguesa + Drawer ----------
  Widget _buildMobile(BuildContext context) {
    final current = _destinations[_currentIndex(context)];
    return Scaffold(
      appBar: AppBar(
        title: Text(current.label),
        backgroundColor: AppTheme.charcoal,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.charcoal,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const _Brand(extended: true),
              const SizedBox(height: 28),
              for (final d in _destinations)
                _MenuItem(
                  destination: d,
                  selected: d.route == current.route,
                  extended: true,
                  onTap: () {
                    Navigator.pop(context);
                    context.go(d.route);
                  },
                ),
              const Spacer(),
              const Divider(color: Colors.white12, height: 1),
              _UserFooter(extended: true, onLogout: () => _logout(context)),
            ],
          ),
        ),
      ),
      body: child,
    );
  }
}

/// Logo + nombre de la app en el sidebar.
class _Brand extends StatelessWidget {
  const _Brand({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        AppConstants.logoAsset,
        width: extended ? 64 : 44,
        height: extended ? 64 : 44,
        fit: BoxFit.cover,
      ),
    );
    if (!extended) return Center(child: logo);
    return Column(
      children: [
        logo,
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            children: const [
              TextSpan(text: 'Pro', style: TextStyle(color: AppTheme.gold)),
              TextSpan(text: 'Dentist', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        Text(
          AppConstants.appSubtitle,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppTheme.silver, letterSpacing: 2),
        ),
      ],
    );
  }
}

/// Item del menu lateral con resaltado dorado redondeado.
class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final ({String route, IconData icon, String label}) destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.gold : AppTheme.silver;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected
            ? AppTheme.gold.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: extended ? 14 : 0, vertical: 12),
            child: extended
                ? Row(
                    children: [
                      Icon(destination.icon, color: color, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        destination.label,
                        style: TextStyle(
                          color: selected ? Colors.white : AppTheme.silver,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  )
                : Tooltip(
                    message: destination.label,
                    child: Icon(destination.icon, color: color, size: 24),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Usuario y cerrar sesion al pie del sidebar.
class _UserFooter extends StatelessWidget {
  const _UserFooter({required this.extended, required this.onLogout});

  final bool extended;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    if (!extended) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: IconButton(
          tooltip: 'Cerrar sesion (${Session.fullName ?? ''})',
          onPressed: onLogout,
          icon: const Icon(Icons.logout, color: AppTheme.silver),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: AppTheme.gold.withValues(alpha: 0.2),
            child: Text(
              (Session.fullName ?? '?').isEmpty
                  ? '?'
                  : Session.fullName![0].toUpperCase(),
              style: const TextStyle(
                  color: AppTheme.gold, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Session.fullName ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  Session.role ?? '',
                  style:
                      const TextStyle(color: AppTheme.silver, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: AppTheme.silver, size: 20),
          ),
        ],
      ),
    );
  }
}
