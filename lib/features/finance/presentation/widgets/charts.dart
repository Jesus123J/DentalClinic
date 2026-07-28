import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/finance_models.dart';

/// Paleta de datos validada (CVD-safe en claro y oscuro).
class ChartColors {
  ChartColors._();

  static const incomeLight = Color(0xFF2A78D6); // azul
  static const incomeDark = Color(0xFF3987E5);
  static const expenseLight = Color(0xFFEB6834); // naranja
  static const expenseDark = Color(0xFFD95926);

  static Color income(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? incomeDark : incomeLight;
  static Color expense(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? expenseDark : expenseLight;

  static Color grid(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? const Color(0xFF2C2C2A)
          : const Color(0xFFE1E0D9);
  static Color muted(BuildContext c) => const Color(0xFF898781);
}

final _money = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
final _moneyShort = NumberFormat.compactCurrency(locale: 'es_PE', symbol: 'S/');

String formatMoney(double v) => _money.format(v);

/// Barras agrupadas: ingresos vs gastos por mes.
class IncomeExpenseChart extends StatefulWidget {
  const IncomeExpenseChart({super.key, required this.series});

  final List<MonthPoint> series;

  @override
  State<IncomeExpenseChart> createState() => _IncomeExpenseChartState();
}

class _IncomeExpenseChartState extends State<IncomeExpenseChart> {
  int? _hovered;

  @override
  Widget build(BuildContext context) {
    final series = widget.series;
    if (series.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Sin datos en el periodo.')),
      );
    }
    final maxValue = series
        .expand((p) => [p.income, p.expenses])
        .fold<double>(0, (a, b) => b > a ? b : a);
    final scale = maxValue <= 0 ? 1.0 : maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Leyenda (identidad nunca solo por color: color + etiqueta)
        Row(
          children: [
            _LegendDot(color: ChartColors.income(context), label: 'Ingresos'),
            const SizedBox(width: 16),
            _LegendDot(color: ChartColors.expense(context), label: 'Gastos'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < series.length; i++)
                Expanded(
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hovered = i),
                    onExit: (_) => setState(() => _hovered = null),
                    child: Tooltip(
                      richMessage: TextSpan(
                        children: [
                          TextSpan(
                            text: '${_monthLabel(series[i].month)}\n',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                              text:
                                  'Ingresos: ${formatMoney(series[i].income)}\n'
                                  'Gastos: ${formatMoney(series[i].expenses)}'),
                        ],
                      ),
                      child: _MonthBars(
                        point: series[i],
                        scale: scale,
                        highlighted: _hovered == null || _hovered == i,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: ChartColors.grid(context)),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final p in series)
              Expanded(
                child: Text(
                  _monthLabel(p.month),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11, color: ChartColors.muted(context)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static String _monthLabel(String yyyyMM) {
    final parts = yyyyMM.split('-');
    if (parts.length != 2) return yyyyMM;
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Set', 'Oct', 'Nov', 'Dic',
    ];
    final m = int.tryParse(parts[1]) ?? 1;
    return months[(m - 1).clamp(0, 11)];
  }
}

class _MonthBars extends StatelessWidget {
  const _MonthBars({
    required this.point,
    required this.scale,
    required this.highlighted,
  });

  final MonthPoint point;
  final double scale;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Bar(
                height: (point.income / scale) * h,
                color: ChartColors.income(context),
                dim: !highlighted,
              ),
              const SizedBox(width: 2), // separador de 2px entre barras
              _Bar(
                height: (point.expenses / scale) * h,
                color: ChartColors.expense(context),
                dim: !highlighted,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color, this.dim = false});

  final double height;
  final Color color;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height.isFinite && height > 0 ? height : 2,
        constraints: const BoxConstraints(maxWidth: 22),
        width: double.infinity,
        decoration: BoxDecoration(
          color: dim ? color.withValues(alpha: 0.35) : color,
          // extremos redondeados solo arriba, anclados a la linea base
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Ranking horizontal: tratamientos que mas ingresos generaron.
class TopTreatmentsChart extends StatelessWidget {
  const TopTreatmentsChart({super.key, required this.items});

  final List<TopTreatment> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Text('Aun no hay servicios cobrados.')),
      );
    }
    final max = items.fold<double>(0, (a, t) => t.amount > a ? t.amount : a);
    final color = ChartColors.income(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(t.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    const SizedBox(width: 12),
                    Text('${t.qty}x',
                        style: TextStyle(
                            fontSize: 12, color: ChartColors.muted(context))),
                    const SizedBox(width: 10),
                    Text(
                      formatMoney(t.amount),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                LayoutBuilder(
                  builder: (context, c) => Container(
                    height: 8,
                    width: max <= 0 ? 0 : (t.amount / max) * c.maxWidth,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Tarjeta de indicador (KPI) del panel financiero.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.hint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (hint != null)
              Text(hint!,
                  style: TextStyle(
                      fontSize: 11, color: ChartColors.muted(context))),
          ],
        ),
      ),
    );
  }
}

String formatMoneyShort(double v) => _moneyShort.format(v);
