import 'package:go_router/go_router.dart';

import '../../features/appointments/presentation/pages/appointments_page.dart';
import '../../features/billing/presentation/pages/billing_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/patients/presentation/pages/patients_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/treatments/presentation/pages/treatments_page.dart';
import '../widgets/main_layout.dart';

/// Configuracion de rutas de la aplicacion.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/patients',
            builder: (context, state) => const PatientsPage(),
          ),
          GoRoute(
            path: '/appointments',
            builder: (context, state) => const AppointmentsPage(),
          ),
          GoRoute(
            path: '/treatments',
            builder: (context, state) => const TreatmentsPage(),
          ),
          GoRoute(
            path: '/billing',
            builder: (context, state) => const BillingPage(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsPage(),
          ),
        ],
      ),
    ],
  );
}
