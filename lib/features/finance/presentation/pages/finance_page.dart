import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/finance_repository.dart';
import '../../domain/entities/finance_models.dart';
import '../widgets/charts.dart';

/// Panel financiero: indicadores, ingresos vs gastos y ranking de servicios.
class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final _repo = FinanceRepository();

  late DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late DateTime _to = DateTime.now();
  FinanceSummary? _summary;
  bool _loading = true;
  String? _error;

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
      final s = await _repo.summary(_from, _to);
      if (!mounted) return;
      setState(() {
        _summary = s;
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

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = picked.end;
      });
      _load();
    }
  }

  void _preset(String key) {
    final now = DateTime.now();
    setState(() {
      switch (key) {
        case 'hoy':
          _from = DateTime(now.year, now.month, now.day);
          _to = now;
        case 'semana':
          _from = now.subtract(const Duration(days: 6));
          _to = now;
        case 'mes':
          _from = DateTime(now.year, now.month, 1);
          _to = now;
        case 'anio':
          _from = DateTime(now.year, 1, 1);
          _to = now;
      }
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Finanzas',
                  style: Theme.of(context).textTheme.headlineMedium),
              // Filtros en una sola fila sobre las graficas
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'hoy', label: Text('Hoy')),
                  ButtonSegment(value: 'semana', label: Text('7 dias')),
                  ButtonSegment(value: 'mes', label: Text('Este mes')),
                  ButtonSegment(value: 'anio', label: Text('Ano')),
                ],
                selected: const {},
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                onSelectionChanged: (s) => _preset(s.first),
              ),
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: Text('${fmt.format(_from)} - ${fmt.format(_to)}'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
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
    final s = _summary!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final tiles = [
                StatTile(
                  label: 'Ingresos del periodo',
                  value: formatMoney(s.income),
                  icon: Icons.trending_up,
                  color: ChartColors.income(context),
                  hint: '${s.salesCount} cobros',
                ),
                StatTile(
                  label: 'Gastos del periodo',
                  value: formatMoney(s.expenses),
                  icon: Icons.trending_down,
                  color: ChartColors.expense(context),
                ),
                StatTile(
                  label: 'Ganancia',
                  value: formatMoney(s.profit),
                  icon: Icons.savings_outlined,
                  color: s.profit >= 0
                      ? const Color(0xFF0CA30C)
                      : const Color(0xFFD03B3B),
                  hint: 'Ingresos - gastos',
                ),
                StatTile(
                  label: 'Cobrado hoy',
                  value: formatMoney(s.today),
                  icon: Icons.today_outlined,
                  color: const Color(0xFFD9A521),
                ),
                if (s.pending > 0)
                  StatTile(
                    label: 'Por cobrar',
                    value: formatMoney(s.pending),
                    icon: Icons.pending_actions_outlined,
                    color: const Color(0xFFFAB219),
                    hint: 'Saldos pendientes',
                  ),
              ];
              final columns = c.maxWidth < 700
                  ? 1
                  : c.maxWidth < 1100
                      ? 2
                      : tiles.length.clamp(1, 5);
              final width =
                  (c.maxWidth - (columns - 1) * 16) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final t in tiles) SizedBox(width: width, child: t),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 900;
              final chart = _ChartCard(
                title: 'Ingresos vs gastos',
                subtitle: 'Ultimos 6 meses',
                child: IncomeExpenseChart(series: s.series),
              );
              final top = _ChartCard(
                title: 'Servicios mas vendidos',
                subtitle: 'Por ingresos del periodo',
                child: TopTreatmentsChart(items: s.topTreatments),
              );
              if (!wide) {
                return Column(
                  children: [chart, const SizedBox(height: 16), top],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: chart),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: top),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
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
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
