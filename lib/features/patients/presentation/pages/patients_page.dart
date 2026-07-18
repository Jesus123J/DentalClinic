import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/patient_repository_impl.dart';
import '../../domain/entities/patient.dart';
import '../widgets/patient_form_dialog.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final _repo = PatientRepositoryImpl();
  final _searchController = TextEditingController();

  List<Patient> _patients = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final patients = await _repo.getAll(search: _searchController.text);
      if (!mounted) return;
      setState(() {
        _patients = patients;
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
    final patient = await PatientFormDialog.show(context);
    if (patient == null) return;
    await _repo.create(patient);
    _load();
  }

  Future<void> _edit(Patient patient) async {
    final updated = await PatientFormDialog.show(context, patient: patient);
    if (updated == null) return;
    await _repo.update(updated);
    _load();
  }

  Future<void> _delete(Patient patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar paciente'),
        content: Text(
            'Se eliminara a ${patient.fullName} junto con sus citas e historia clinica. Continuar?'),
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
    await _repo.delete(patient.id!);
    _load();
  }

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
              Text('Pacientes',
                  style: Theme.of(context).textTheme.headlineMedium),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o DNI…',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.person_add),
                label: const Text('Nuevo paciente'),
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
    if (_patients.isEmpty) {
      return const Center(child: Text('No hay pacientes registrados.'));
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
              DataColumn(label: Text('Paciente')),
              DataColumn(label: Text('DNI')),
              DataColumn(label: Text('Telefono')),
              DataColumn(label: Text('Nacimiento')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: [
              for (final p in _patients)
                DataRow(cells: [
                  DataCell(Text(p.fullName)),
                  DataCell(Text(p.documentId ?? '-')),
                  DataCell(Text(p.phone ?? '-')),
                  DataCell(Text(p.birthDate == null
                      ? '-'
                      : DateFormat('dd/MM/yyyy').format(p.birthDate!))),
                  DataCell(Row(children: [
                    IconButton(
                      tooltip: 'Historia clinica',
                      icon: const Icon(Icons.folder_shared_outlined),
                      onPressed: () async {
                        await context.push('/patients/history', extra: p);
                      },
                    ),
                    IconButton(
                      tooltip: 'Editar',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _edit(p),
                    ),
                    IconButton(
                      tooltip: 'Eliminar',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(p),
                    ),
                  ])),
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
