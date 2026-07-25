import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_theme.dart';
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

  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  /// Citas del mes visible agrupadas por dia (para los marcadores).
  Map<DateTime, List<Appointment>> _monthEvents = {};
  List<Appointment> _dayAppointments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMonth();
    _loadDay();
  }

  DateTime _dayKey(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  Future<void> _loadMonth() async {
    try {
      final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
      final last = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
      final appointments = await _repo.getByRange(first, last);
      if (!mounted) return;
      final map = <DateTime, List<Appointment>>{};
      for (final a in appointments) {
        map.putIfAbsent(_dayKey(a.dateTime), () => []).add(a);
      }
      setState(() => _monthEvents = map);
    } catch (_) {
      // los marcadores son informativos; el error visible lo da _loadDay
    }
  }

  Future<void> _loadDay() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final appointments = await _repo.getByDate(_selectedDate);
      if (!mounted) return;
      setState(() {
        _dayAppointments = appointments;
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

  Future<void> _create() async {
    final appointment =
        await _AppointmentFormDialog.show(context, _selectedDate);
    if (appointment == null) return;
    await _repo.create(appointment);
    setState(() {
      _selectedDate = appointment.dateTime;
      _focusedMonth = appointment.dateTime;
    });
    _loadMonth();
    _loadDay();
  }

  Future<void> _changeStatus(Appointment a, AppointmentStatus status) async {
    await _repo.updateStatus(a.id!, status);
    _loadMonth();
    _loadDay();
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
    _loadMonth();
    _loadDay();
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Citas', style: Theme.of(context).textTheme.headlineMedium),
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: const Text('Nueva cita'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 950;
                final calendar = _buildCalendar();
                final list = _buildDayList();
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 420, child: calendar),
                      const SizedBox(width: 20),
                      Expanded(child: list),
                    ],
                  );
                }
                return ListView(
                  children: [
                    calendar,
                    const SizedBox(height: 16),
                    SizedBox(height: 420, child: list),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TableCalendar<Appointment>(
          locale: 'es',
          firstDay: DateTime(2020),
          lastDay: DateTime(2100),
          focusedDay: _focusedMonth,
          selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
          eventLoader: (day) => _monthEvents[_dayKey(day)] ?? const [],
          startingDayOfWeek: StartingDayOfWeek.monday,
          availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppTheme.gold,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold),
            markerDecoration: const BoxDecoration(
              color: AppTheme.charcoal,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 4,
          ),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDate = selected;
              _focusedMonth = focused;
            });
            _loadDay();
          },
          onPageChanged: (focused) {
            _focusedMonth = focused;
            _loadMonth();
          },
        ),
      ),
    );
  }

  Widget _buildDayList() {
    final title = DateFormat("EEEE dd 'de' MMMM", 'es').format(_selectedDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title[0].toUpperCase() + title.substring(1),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildBody()),
      ],
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
            FilledButton(onPressed: _loadDay, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_dayAppointments.isEmpty) {
      return const Center(child: Text('No hay citas para esta fecha.'));
    }
    return ListView.separated(
      itemCount: _dayAppointments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final a = _dayAppointments[index];
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
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Text('Solo el paciente es obligatorio.',
                style: Theme.of(context).textTheme.bodySmall),
            DropdownButtonFormField<Patient>(
              initialValue: _selectedPatient,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Paciente *'),
              items: [
                for (final p in _patients)
                  DropdownMenuItem(
                    value: p,
                    child: Text(p.fullName,
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
              ],
              onChanged: (p) => setState(() => _selectedPatient = p),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event),
                    label: Text(DateFormat('dd/MM/yyyy').format(_date)),
                  ),
                ),
                const SizedBox(width: 16),
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
              decoration: const InputDecoration(
                  labelText: 'Motivo de la cita (opcional)'),
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
