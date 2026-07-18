import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../reports/data/repositories/report_repository.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _repo = ReportRepository();
  ({int totalPatients, int todayAppointments, int pendingAppointments})? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final stats = await _repo.dashboardStats();
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _error = 'No se pudo conectar al servidor API (server/): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium),
          Text(
            DateFormat("EEEE dd 'de' MMMM yyyy", 'es').format(DateTime.now()),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 8),
                    FilledButton(
                        onPressed: _load, child: const Text('Reintentar')),
                  ],
                ),
              ),
            )
          else if (_stats == null)
            const Center(child: CircularProgressIndicator())
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  _StatCard(
                    icon: Icons.people_outline,
                    label: 'Pacientes registrados',
                    value: '${_stats!.totalPatients}',
                    color: Colors.teal,
                  ),
                  _StatCard(
                    icon: Icons.today_outlined,
                    label: 'Citas de hoy',
                    value: '${_stats!.todayAppointments}',
                    color: Colors.indigo,
                  ),
                  _StatCard(
                    icon: Icons.pending_actions_outlined,
                    label: 'Citas pendientes',
                    value: '${_stats!.pendingAppointments}',
                    color: Colors.orange,
                  ),
                ];
                // En pantallas angostas las tarjetas se apilan en vertical.
                if (constraints.maxWidth < 720) {
                  return Column(
                    children: [
                      for (final c in cards)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                              width: double.infinity, child: c),
                        ),
                    ],
                  );
                }
                return Row(
                  children: [
                    for (final c in cards)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: c,
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: Theme.of(context).textTheme.headlineMedium),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
