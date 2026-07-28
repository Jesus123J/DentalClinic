import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../appointments/domain/entities/appointment.dart';
import '../../../finance/presentation/widgets/charts.dart';
import '../../data/repositories/patient_repository_impl.dart';
import '../../domain/entities/patient_summary.dart';

/// Resumen del paciente: cuanto gasto, cuantas veces vino y que se le hizo.
class PatientSummaryTab extends StatefulWidget {
  const PatientSummaryTab({super.key, required this.patientId});

  final int patientId;

  @override
  State<PatientSummaryTab> createState() => _PatientSummaryTabState();
}

class _PatientSummaryTabState extends State<PatientSummaryTab> {
  final _repo = PatientRepositoryImpl();
  PatientSummary? _data;
  bool _loading = true;
  String? _error;

  static final _date = DateFormat('dd/MM/yyyy');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.summary(widget.patientId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    final d = _data!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTiles(d),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 900;
              final sales = _SectionCard(
                title: 'Historial de pagos',
                subtitle: d.sales.isEmpty
                    ? 'Sin cobros registrados'
                    : '${d.salesCount} cobros',
                child: _buildSales(d),
              );
              final visits = _SectionCard(
                title: 'Historial de citas',
                subtitle: d.appointments.isEmpty
                    ? 'Sin citas registradas'
                    : '${d.appointments.length} citas',
                child: _buildAppointments(d),
              );
              if (!wide) {
                return Column(
                  children: [sales, const SizedBox(height: 16), visits],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: sales),
                  const SizedBox(width: 16),
                  Expanded(child: visits),
                ],
              );
            },
          ),
          if (d.topTreatments.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Servicios realizados',
              subtitle: 'Lo que mas se le ha hecho a este paciente',
              child: TopTreatmentsChart(items: d.topTreatments),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTiles(PatientSummary d) {
    final tiles = <Widget>[
      StatTile(
        label: 'Total gastado',
        value: formatMoney(d.spent),
        icon: Icons.payments_outlined,
        color: ChartColors.income(context),
        hint: '${d.salesCount} cobros',
      ),
      StatTile(
        label: 'Visitas atendidas',
        value: '${d.visits}',
        icon: Icons.event_available_outlined,
        color: const Color(0xFFD9A521),
        hint: d.lastVisit == null
            ? 'Sin visitas aun'
            : 'Ultima: ${_date.format(d.lastVisit!)}',
      ),
      StatTile(
        label: 'Registros clinicos',
        value: '${d.recordsCount}',
        icon: Icons.medical_information_outlined,
        color: const Color(0xFF9AA5B1),
        hint: d.firstVisit == null
            ? null
            : 'Paciente desde ${_date.format(d.firstVisit!)}',
      ),
      if (d.due > 0)
        StatTile(
          label: 'Saldo pendiente',
          value: formatMoney(d.due),
          icon: Icons.error_outline,
          color: const Color(0xFFD03B3B),
          hint: 'Por cobrar',
        )
      else
        StatTile(
          label: 'Estado de cuenta',
          value: 'Al dia',
          icon: Icons.verified_outlined,
          color: const Color(0xFF0CA30C),
          hint: 'Sin deudas',
        ),
      if (d.nextVisit != null)
        StatTile(
          label: 'Proxima cita',
          value: _date.format(d.nextVisit!),
          icon: Icons.schedule_outlined,
          color: ChartColors.expense(context),
          hint: DateFormat('HH:mm').format(d.nextVisit!),
        ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth < 620
            ? 1
            : c.maxWidth < 1000
                ? 2
                : tiles.length.clamp(1, 5);
        final width = (c.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final t in tiles) SizedBox(width: width, child: t),
          ],
        );
      },
    );
  }

  Widget _buildSales(PatientSummary d) {
    if (d.sales.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('Aun no se le ha cobrado nada.')),
      );
    }
    return Column(
      children: [
        for (final s in d.sales)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _dateTime.format(s.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      _StatusChip(status: s.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Que se le hizo en ese cobro
                  for (final i in s.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${i.qty}x  ${i.name}',
                                style:
                                    Theme.of(context).textTheme.bodyMedium),
                          ),
                          Text(formatMoney(i.subtotal),
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.method.label,
                          style: Theme.of(context).textTheme.bodySmall),
                      Row(
                        children: [
                          if (s.status == 'pendiente' && s.due > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Text(
                                'debe ${formatMoney(s.due)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFFD03B3B)),
                              ),
                            ),
                          Text(
                            formatMoney(s.total),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAppointments(PatientSummary d) {
    if (d.appointments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('Sin citas registradas.')),
      );
    }
    Color color(AppointmentStatus s) => switch (s) {
          AppointmentStatus.pendiente => const Color(0xFFFAB219),
          AppointmentStatus.atendida => const Color(0xFF0CA30C),
          AppointmentStatus.cancelada => const Color(0xFFD03B3B),
        };
    return Column(
      children: [
        for (final a in d.appointments)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: color(a.status),
                shape: BoxShape.circle,
              ),
            ),
            title: Text(_dateTime.format(a.dateTime),
                style: Theme.of(context).textTheme.bodyMedium),
            subtitle: Text(a.reason ?? 'Sin motivo registrado',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(
              a.status.label,
              style: TextStyle(fontSize: 12, color: color(a.status)),
            ),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'pagado' => const Color(0xFF0CA30C),
      'pendiente' => const Color(0xFFFAB219),
      _ => const Color(0xFFD03B3B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text(subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: ChartColors.muted(context))),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
