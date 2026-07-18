import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/pdf/pdf_exporter.dart';
import '../../data/repositories/report_repository.dart';

/// Reporte de atenciones de pacientes por rango de fechas.
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _repo = ReportRepository();

  late DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  late DateTime _to = DateTime.now();
  List<PatientReportRow> _rows = [];
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
      final rows = await _repo.appointmentsByRange(_from, _to);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error de base de datos: $e';
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
              Text('Reporte de pacientes',
                  style: Theme.of(context).textTheme.headlineMedium),
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: Text('${fmt.format(_from)} — ${fmt.format(_to)}'),
              ),
              Text('${_rows.length} atenciones',
                  style: Theme.of(context).textTheme.titleMedium),
              FilledButton.icon(
                onPressed: _rows.isEmpty
                    ? null
                    : () => PdfExporter.appointmentsReport(
                        from: _from, to: _to, rows: _rows),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Exportar PDF'),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
    if (_rows.isEmpty) {
      return const Center(
          child: Text('Sin citas registradas en este rango de fechas.'));
    }
    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Fecha y hora')),
                  DataColumn(label: Text('Paciente')),
                  DataColumn(label: Text('DNI')),
                  DataColumn(label: Text('Motivo')),
                  DataColumn(label: Text('Estado')),
                ],
                rows: [
                  for (final r in _rows)
                    DataRow(cells: [
                      DataCell(Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(r.dateTime))),
                      DataCell(Text(r.patientName)),
                      DataCell(Text(r.documentId)),
                      DataCell(Text(r.reason)),
                      DataCell(Text(r.status)),
                    ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
