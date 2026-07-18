import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../patients/data/repositories/patient_repository_impl.dart';
import '../../../patients/domain/entities/patient.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../domain/entities/appointment.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final _repo = AppointmentRepository();
  DateTime _selectedDate = DateTime.now();
  List<Appointment> _appointments = [];
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
      final appointments = await _repo.getByDate(_selectedDate);
      if (!mounted) return;
      setState(() {
        _appointments = appointments;
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _load();
    }
  }

  Future<void> _create() async {
    final appointment =
        await _AppointmentFormDialog.show(context, _selectedDate);
    if (appointment == null) return;
    await _repo.create(appointment);
    setState(() => _selectedDate = appointment.dateTime);
    _load();
  }

  Future<void> _changeStatus(Appointment a, AppointmentStatus status) async {
    await _repo.updateStatus(a.id!, status);
    _load();
  }

  Future<void> _delete(Appointment a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cita'),
        content: Text('Eliminar la cita de ${a.patientName}?'),
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
    await _repo.delete(a.id!);
    _load();
  }

  Color _statusColor(AppointmentStatus status) => switch (status) {
        AppointmentStatus.pendiente => Colors.orange,
        AppointmentStatus.atendida => Colors.green,
        AppointmentStatus.cancelada => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Citas', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(width: 24),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event),
                label: Text(
                    DateFormat('EEEE dd/MM/yyyy', 'es').format(_selectedDate)),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: const Text('Nueva cita'),
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
    if (_appointments.isEmpty) {
      return const Center(child: Text('No hay citas para esta fecha.'));
    }
    return ListView.separated(
      itemCount: _appointments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final a = _appointments[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _statusColor(a.status).withValues(alpha: 0.15),
              child: Text(
                DateFormat('HH:mm').format(a.dateTime),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _statusColor(a.status),
                ),
              ),
            ),
            title: Text(a.patientName),
            subtitle: Text(a.reason ?? 'Sin motivo registrado'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(a.status.label),
                  labelStyle: TextStyle(color: _statusColor(a.status)),
                  side: BorderSide(color: _statusColor(a.status)),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Acciones',
                  onSelected: (value) {
                    switch (value) {
                      case 'atendida':
                        _changeStatus(a, AppointmentStatus.atendida);
                      case 'cancelada':
                        _changeStatus(a, AppointmentStatus.cancelada);
                      case 'pendiente':
                        _changeStatus(a, AppointmentStatus.pendiente);
                      case 'eliminar':
                        _delete(a);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                        value: 'atendida', child: Text('Marcar atendida')),
                    PopupMenuItem(
                        value: 'pendiente', child: Text('Marcar pendiente')),
                    PopupMenuItem(
                        value: 'cancelada', child: Text('Cancelar cita')),
                    PopupMenuDivider(),
                    PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AppointmentFormDialog extends StatefulWidget {
  const _AppointmentFormDialog({required this.initialDate});

  final DateTime initialDate;

  static Future<Appointment?> show(BuildContext context, DateTime initialDate) {
    return showDialog<Appointment>(
      context: context,
      builder: (_) => _AppointmentFormDialog(initialDate: initialDate),
    );
  }

  @override
  State<_AppointmentFormDialog> createState() => _AppointmentFormDialogState();
}

class _AppointmentFormDialogState extends State<_AppointmentFormDialog> {
  final _patientRepo = PatientRepositoryImpl();
  final _reason = TextEditingController();

  List<Patient> _patients = [];
  Patient? _selectedPatient;
  late DateTime _date = widget.initialDate;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    final patients = await _patientRepo.getAll();
    if (!mounted) return;
    setState(() => _patients = patients);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un paciente')),
      );
      return;
    }
    Navigator.of(context).pop(Appointment(
      patientId: _selectedPatient!.id!,
      dateTime: DateTime(
          _date.year, _date.month, _date.day, _time.hour, _time.minute),
      reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva cita'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Patient>(
              initialValue: _selectedPatient,
              decoration: const InputDecoration(labelText: 'Paciente *'),
              items: [
                for (final p in _patients)
                  DropdownMenuItem(value: p, child: Text(p.fullName)),
              ],
              onChanged: (p) => setState(() => _selectedPatient = p),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event),
                    label: Text(DateFormat('dd/MM/yyyy').format(_date)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _reason,
              decoration:
                  const InputDecoration(labelText: 'Motivo de la cita'),
            ),
          ],
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
