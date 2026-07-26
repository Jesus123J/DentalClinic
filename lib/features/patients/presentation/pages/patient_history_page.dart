import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/pdf/pdf_exporter.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../data/repositories/clinical_record_repository.dart';
import '../../data/repositories/odontogram_repository.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/entities/clinical_record.dart';
import '../../domain/entities/patient.dart';
import '../widgets/odontogram_view.dart';

/// Historia clinica odontologica de un paciente:
/// odontograma interactivo + registros clinicos detallados.
class PatientHistoryPage extends StatefulWidget {
  const PatientHistoryPage({super.key, required this.patient});

  final Patient patient;

  @override
  State<PatientHistoryPage> createState() => _PatientHistoryPageState();
}

class _PatientHistoryPageState extends State<PatientHistoryPage> {
  final _repo = ClinicalRecordRepository();
  final _odontogramRepo = OdontogramRepository();
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

  Future<void> _exportPdf() async {
    final teeth = await _odontogramRepo.getByPatient(widget.patient.id!);
    await PdfExporter.patientHistory(
      patient: widget.patient,
      records: _records,
      teeth: teeth.values.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Historia clinica — ${p.fullName}'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: _loading ? null : _exportPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Exportar PDF'),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.grid_view_outlined), text: 'Odontograma'),
              Tab(
                  icon: Icon(Icons.receipt_long_outlined),
                  text: 'Registros clinicos'),
              Tab(icon: Icon(Icons.attach_file), text: 'Archivos'),
            ],
          ),
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
                      _InfoChip(
                          label: 'Alergias', value: p.allergies ?? 'Ninguna'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    OdontogramView(patientId: p.id!),
                    _buildRecords(),
                    _AttachmentsTab(patientId: p.id!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecords() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_records.isEmpty) {
      return const Center(child: Text('Sin registros en la historia clinica.'));
    }
    return ListView.separated(
      itemCount: _records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final r = _records[index];
        return Card(
          child: ExpansionTile(
            shape: const Border(),
            leading: const CircleAvatar(
              child: Icon(Icons.medical_information_outlined),
            ),
            title: Text(r.diagnosis),
            subtitle: Text([
              DateFormat('dd/MM/yyyy').format(r.recordDate),
              if (r.tooth != null && r.tooth!.isNotEmpty) 'Pieza ${r.tooth}',
              if (r.procedureType != null) r.procedureType!,
            ].join('  ·  ')),
            trailing: IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteRecord(r),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(72, 0, 24, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detail('Motivo de consulta', r.chiefComplaint),
              _detail('Examen clinico', r.clinicalExam),
              _detail('Tratamiento', r.treatment),
              _detail('Receta / indicaciones', r.prescription),
              _detail('Observaciones', r.observations),
            ],
          ),
        );
      },
    );
  }

  Widget _detail(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }
}

/// Pestana de archivos adjuntos: radiografias, fotos y PDFs del paciente.
class _AttachmentsTab extends StatefulWidget {
  const _AttachmentsTab({required this.patientId});

  final int patientId;

  @override
  State<_AttachmentsTab> createState() => _AttachmentsTabState();
}

class _AttachmentsTabState extends State<_AttachmentsTab> {
  final _repo = AttachmentRepository();
  List<Attachment> _files = [];
  bool _loading = true;
  bool _uploading = false;
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
      final files = await _repo.getByPatient(widget.patientId);
      if (!mounted) return;
      setState(() {
        _files = files;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _upload() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'pdf'],
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file == null || file.bytes == null) return;
    if (file.size > 15 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El archivo supera los 15 MB')));
      return;
    }
    setState(() => _uploading = true);
    try {
      await _repo.upload(
        patientId: widget.patientId,
        filename: file.name,
        bytes: file.bytes!,
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo subir: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// Vista previa dentro de la app: imagenes ampliables y PDFs con visor.
  Future<void> _preview(Attachment file) async {
    showDialog(
      context: context,
      builder: (_) => const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    Uint8List bytes;
    try {
      bytes = Uint8List.fromList(await _repo.download(file.id));
    } catch (e) {
      if (!mounted) return;
      // rootNavigator: los dialogos viven en el navegador raiz;
      // sin esto se cerraba la pagina en lugar del dialogo de carga.
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo abrir: $e')));
      return;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // cierra el loading

    if (file.isImage) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(file.name,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: InteractiveViewer(
                    maxScale: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.memory(bytes, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (file.isPdf) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 750),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(file.name,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PdfPreview(
                    build: (_) async => bytes,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    pdfFileName: file.name,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      await _openInBrowser(file);
    }
  }

  Future<void> _openInBrowser(Attachment file) async {
    await launchUrl(
      Uri.parse(_repo.viewUrl(file.id)),
      webOnlyWindowName: '_blank',
    );
  }

  Future<void> _delete(Attachment file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar archivo'),
        content: Text('Se eliminara "${file.name}" definitivamente.'),
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
    await _repo.delete(file.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Radiografias, fotos o historias anteriores en PDF (max. 15 MB).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            FilledButton.icon(
              onPressed: _uploading ? null : _upload,
              icon: _uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_file),
              label: Text(_uploading ? 'Subiendo…' : 'Subir archivo'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
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
    if (_files.isEmpty) {
      return const Center(
          child: Text('Sin archivos adjuntos. Usa "Subir archivo".'));
    }
    return ListView.separated(
      itemCount: _files.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final f = _files[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(f.isPdf
                  ? Icons.picture_as_pdf_outlined
                  : f.isImage
                      ? Icons.image_outlined
                      : Icons.insert_drive_file_outlined),
            ),
            title: Text(f.name, overflow: TextOverflow.ellipsis),
            subtitle: Text(
                '${f.sizeLabel} · ${DateFormat('dd/MM/yyyy HH:mm').format(f.uploadedAt)}'),
            onTap: () => _preview(f),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Vista previa',
                  icon: const Icon(Icons.visibility_outlined),
                  onPressed: () => _preview(f),
                ),
                IconButton(
                  tooltip: 'Abrir en el navegador',
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => _openInBrowser(f),
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(f),
                ),
              ],
            ),
          ),
        );
      },
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
  final _chiefComplaint = TextEditingController();
  final _tooth = TextEditingController();
  final _diagnosis = TextEditingController();
  final _clinicalExam = TextEditingController();
  final _treatment = TextEditingController();
  final _prescription = TextEditingController();
  final _observations = TextEditingController();
  String? _procedureType;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    for (final c in [
      _chiefComplaint,
      _tooth,
      _diagnosis,
      _clinicalExam,
      _treatment,
      _prescription,
      _observations,
    ]) {
      c.dispose();
    }
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
      tooth: clean(_tooth),
      procedureType: _procedureType,
      chiefComplaint: clean(_chiefComplaint),
      clinicalExam: clean(_clinicalExam),
      treatment: clean(_treatment),
      prescription: clean(_prescription),
      observations: clean(_observations),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo registro clinico'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
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
                  controller: _chiefComplaint,
                  decoration: const InputDecoration(
                      labelText: 'Motivo de consulta (opcional)',
                      hintText: 'Ej. dolor al masticar del lado derecho'),
                ),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tooth,
                      decoration: const InputDecoration(
                          labelText: 'Pieza(s) dental(es) (opcional)',
                          hintText: 'FDI, ej. 16 o 16, 24'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _procedureType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'Procedimiento (opcional)'),
                      items: [
                        for (final t in kProcedureTypes)
                          DropdownMenuItem(
                            value: t,
                            child: Text(t,
                                overflow: TextOverflow.ellipsis, maxLines: 1),
                          ),
                      ],
                      onChanged: (v) => setState(() => _procedureType = v),
                    ),
                  ),
                ]),
                TextFormField(
                  controller: _diagnosis,
                  decoration:
                      const InputDecoration(labelText: 'Diagnostico *'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _clinicalExam,
                  decoration: const InputDecoration(
                      labelText: 'Examen clinico / hallazgos (opcional)'),
                  maxLines: 2,
                ),
                TextFormField(
                  controller: _treatment,
                  decoration: const InputDecoration(
                      labelText: 'Tratamiento realizado (opcional)'),
                ),
                TextFormField(
                  controller: _prescription,
                  decoration: const InputDecoration(
                      labelText: 'Receta / indicaciones (opcional)',
                      hintText: 'Ej. amoxicilina 500mg c/8h por 7 dias'),
                  maxLines: 2,
                ),
                TextFormField(
                  controller: _observations,
                  decoration: const InputDecoration(
                      labelText: 'Observaciones (opcional)'),
                  maxLines: 2,
                ),
              ],
            ),
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
