import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/appointments/presentation/pages/appointments_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/billing/presentation/pages/billing_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/patients/domain/entities/patient.dart';
import '../../features/patients/presentation/pages/patient_history_page.dart';
import '../../features/patients/presentation/pages/patients_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/treatments/presentation/pages/treatments_page.dart';
import '../auth/session.dart';
import '../widgets/main_layout.dart';

/// Configuracion de rutas de la aplicacion.
class AppRouter {
  AppRouter._();

  /// Cambio de pestana sin animacion: el contenido se reemplaza al instante,
  /// como corresponde en una app de escritorio con menu lateral.
  static GoRoute _tab(String path, Widget page) => GoRoute(
        path: path,
        pageBuilder: (context, state) => NoTransitionPage(child: page),
      );

  static final GoRouter router = GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final goingToLogin = state.uri.path == '/login';
      if (!Session.isLoggedIn && !goingToLogin) return '/login';
      if (Session.isLoggedIn && goingToLogin) return '/dashboard';
      return null;
    },
    routes: [
      _tab('/login', const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          _tab('/dashboard', const DashboardPage()),
          _tab('/patients', const PatientsPage()),
          _tab('/appointments', const AppointmentsPage()),
          _tab('/treatments', const TreatmentsPage()),
          _tab('/billing', const BillingPage()),
          _tab('/reports', const ReportsPage()),
          // La historia clinica se abre "encima" de pacientes: aqui si dejamos
          // una transicion suave de fundido.
          GoRoute(
            path: '/patients/history',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: PatientHistoryPage(patient: state.extra! as Patient),
              transitionDuration: const Duration(milliseconds: 150),
              transitionsBuilder: (context, animation, secondary, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          ),
        ],
      ),
    ],
  );
}
