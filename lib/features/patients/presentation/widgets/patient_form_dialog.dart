import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/patient.dart';

/// Formulario para crear o editar un paciente. Devuelve el [Patient] armado.
class PatientFormDialog extends StatefulWidget {
  const PatientFormDialog({super.key, this.patient});

  final Patient? patient;

  static Future<Patient?> show(BuildContext context, {Patient? patient}) {
    return showDialog<Patient>(
      context: context,
      builder: (_) => PatientFormDialog(patient: patient),
    );
  }

  @override
  State<PatientFormDialog> createState() => _PatientFormDialogState();
}

class _PatientFormDialogState extends State<PatientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.patient?.firstName);
  late final _lastName = TextEditingController(text: widget.patient?.lastName);
  late final _documentId =
      TextEditingController(text: widget.patient?.documentId);
  late final _phone = TextEditingController(text: widget.patient?.phone);
  late final _email = TextEditingController(text: widget.patient?.email);
  late final _allergies = TextEditingController(text: widget.patient?.allergies);
  late final _notes = TextEditingController(text: widget.patient?.notes);
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _birthDate = widget.patient?.birthDate;
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _documentId,
      _phone,
      _email,
      _allergies,
      _notes
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    String? clean(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    Navigator.of(context).pop(Patient(
      id: widget.patient?.id,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      documentId: clean(_documentId),
      phone: clean(_phone),
      email: clean(_email),
      birthDate: _birthDate,
      allergies: clean(_allergies),
      notes: clean(_notes),
      createdAt: widget.patient?.createdAt ?? DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.patient != null;
    return AlertDialog(
      title: Text(isEdit ? 'Editar paciente' : 'Nuevo paciente'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstName,
                      decoration: const InputDecoration(labelText: 'Nombres *'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastName,
                      decoration:
                          const InputDecoration(labelText: 'Apellidos *'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ]),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _documentId,
                      decoration: const InputDecoration(labelText: 'DNI'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phone,
                      decoration: const InputDecoration(labelText: 'Telefono'),
                    ),
                  ),
                ]),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Correo'),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _pickBirthDate,
                    icon: const Icon(Icons.cake_outlined),
                    label: Text(_birthDate == null
                        ? 'Fecha de nacimiento'
                        : DateFormat('dd/MM/yyyy').format(_birthDate!)),
                  ),
                ),
                TextFormField(
                  controller: _allergies,
                  decoration: const InputDecoration(labelText: 'Alergias'),
                ),
                TextFormField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notas'),
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
