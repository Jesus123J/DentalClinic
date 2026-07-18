import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/pdf/pdf_exporter.dart';
import '../../data/repositories/clinical_record_repository.dart';
import '../../domain/entities/clinical_record.dart';
import '../../domain/entities/patient.dart';

/// Historia clinica de un paciente.
class PatientHistoryPage extends StatefulWidget {
  const PatientHistoryPage({super.key, required this.patient});

  final Patient patient;

  @override
  State<PatientHistoryPage> createState() => _PatientHistoryPageState();
}

class _PatientHistoryPageState extends State<PatientHistoryPage> {
  final _repo = ClinicalRecordRepository();
  List<ClinicalRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final records = await _repo.getByPatient(widget.patient.id!);
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _addRecord() async {
    final record = await _RecordFormDialog.show(context, widget.patient.id!);
    if (record == null) return;
    await _repo.create(record);
    _load();
  }

  Future<void> _deleteRecord(ClinicalRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('Se eliminara esta entrada de la historia clinica.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _repo.delete(record.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    return Scaffold(
      appBar: AppBar(
        title: Text('Historia clinica — ${p.fullName}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _loading
                  ? null
                  : () => PdfExporter.patientHistory(
                      patient: p, records: _records),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Exportar PDF'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecord,
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Nuevo registro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 32,
                  runSpacing: 8,
                  children: [
                    _InfoChip(label: 'DNI', value: p.documentId ?? '-'),
                    _InfoChip(label: 'Telefono', value: p.phone ?? '-'),
                    _InfoChip(
                      label: 'Nacimiento',
                      value: p.birthDate == null
                          ? '-'
                          : DateFormat('dd/MM/yyyy').format(p.birthDate!),
                    ),
                    _InfoChip(label: 'Alergias', value: p.allergies ?? 'Ninguna'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _records.isEmpty
                      ? const Center(
                          child: Text('Sin registros en la historia clinica.'))
                      : ListView.separated(
                          itemCount: _records.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final r = _records[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: const Icon(Icons.medical_information_outlined),
                                ),
                                title: Text(r.diagnosis),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(DateFormat('dd/MM/yyyy')
                                        .format(r.recordDate)),
                                    if (r.treatment != null)
                                      Text('Tratamiento: ${r.treatment}'),
                                    if (r.observations != null)
                                      Text('Obs.: ${r.observations}'),
                                  ],
                                ),
                                trailing: IconButton(
                                  tooltip: 'Eliminar',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteRecord(r),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _RecordFormDialog extends StatefulWidget {
  const _RecordFormDialog({required this.patientId});

  final int patientId;

  static Future<ClinicalRecord?> show(BuildContext context, int patientId) {
    return showDialog<ClinicalRecord>(
      context: context,
      builder: (_) => _RecordFormDialog(patientId: patientId),
    );
  }

  @override
  State<_RecordFormDialog> createState() => _RecordFormDialogState();
}

class _RecordFormDialogState extends State<_RecordFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosis = TextEditingController();
  final _treatment = TextEditingController();
  final _observations = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _diagnosis.dispose();
    _treatment.dispose();
    _observations.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    String? clean(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    Navigator.of(context).pop(ClinicalRecord(
      patientId: widget.patientId,
      recordDate: _date,
      diagnosis: _diagnosis.text.trim(),
      treatment: clean(_treatment),
      observations: clean(_observations),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo registro clinico'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: Text(DateFormat('dd/MM/yyyy').format(_date)),
                ),
              ),
              TextFormField(
                controller: _diagnosis,
                decoration: const InputDecoration(labelText: 'Diagnostico *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _treatment,
                decoration: const InputDecoration(labelText: 'Tratamiento'),
              ),
              TextFormField(
                controller: _observations,
                decoration: const InputDecoration(labelText: 'Observaciones'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
