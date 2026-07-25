import 'package:flutter/material.dart';

import '../../data/repositories/odontogram_repository.dart';
import '../../domain/entities/tooth_state.dart';

/// Odontograma interactivo (adulto, notacion FDI):
/// toca una pieza para asignarle estado y nota.
class OdontogramView extends StatefulWidget {
  const OdontogramView({super.key, required this.patientId});

  final int patientId;

  @override
  State<OdontogramView> createState() => _OdontogramViewState();
}

class _OdontogramViewState extends State<OdontogramView> {
  final _repo = OdontogramRepository();
  Map<String, ToothState> _teeth = {};
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
      final teeth = await _repo.getByPatient(widget.patientId);
      if (!mounted) return;
      setState(() {
        _teeth = teeth;
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

  Future<void> _editTooth(String tooth) async {
    final current = _teeth[tooth];
    final result = await _ToothDialog.show(context, tooth, current);
    if (result == null) return;
    try {
      await _repo.save(ToothState(
        patientId: widget.patientId,
        tooth: tooth,
        status: result.status,
        note: result.note,
      ));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
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
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    final affected = _teeth.values.toList()
      ..sort((a, b) => a.tooth.compareTo(b.tooth));
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Toca una pieza para registrar su estado.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          // Leyenda
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in ToothStatus.values)
                Chip(
                  avatar: CircleAvatar(
                    backgroundColor: s == ToothStatus.sano
                        ? Colors.transparent
                        : s.color,
                    child: s == ToothStatus.sano
                        ? const Icon(Icons.circle_outlined, size: 14)
                        : null,
                  ),
                  label: Text(s.label, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Arcada superior',
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    _archRow(kUpperTeeth),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: SizedBox(
                          width: 600, child: Divider(thickness: 1.5)),
                    ),
                    _archRow(kLowerTeeth),
                    const SizedBox(height: 8),
                    Text('Arcada inferior',
                        style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (affected.isNotEmpty) ...[
            Text('Piezas con hallazgos (${affected.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final t in affected)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: t.status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Pieza ${t.tooth} — ${t.status.label}'
                        '${t.note == null || t.note!.isEmpty ? '' : ' · ${t.note}'}'),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _archRow(List<String> teeth) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < teeth.length; i++) ...[
          if (i == 8)
            Container(
              width: 1.5,
              height: 44,
              color: Theme.of(context).dividerColor,
              margin: const EdgeInsets.symmetric(horizontal: 6),
            ),
          _ToothBox(
            tooth: teeth[i],
            state: _teeth[teeth[i]],
            onTap: () => _editTooth(teeth[i]),
          ),
        ],
      ],
    );
  }
}

class _ToothBox extends StatelessWidget {
  const _ToothBox({required this.tooth, this.state, required this.onTap});

  final String tooth;
  final ToothState? state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = state?.status ?? ToothStatus.sano;
    final isHealthy = status == ToothStatus.sano;
    final isExtracted = status == ToothStatus.extraido;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: isHealthy
            ? 'Pieza $tooth — Sano'
            : 'Pieza $tooth — ${status.label}'
                '${state?.note == null || state!.note!.isEmpty ? '' : '\n${state!.note}'}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 34,
            height: 44,
            decoration: BoxDecoration(
              color: isHealthy
                  ? Theme.of(context).colorScheme.surface
                  : status.color.withValues(alpha: 0.85),
              border: Border.all(
                color: isHealthy
                    ? Theme.of(context).dividerColor
                    : status.color,
                width: 1.4,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: isExtracted
                ? const Center(
                    child: Icon(Icons.close, size: 20, color: Colors.white))
                : Center(
                    child: Text(
                      tooth,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isHealthy
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.white,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ToothDialogResult {
  const _ToothDialogResult(this.status, this.note);
  final ToothStatus status;
  final String? note;
}

class _ToothDialog extends StatefulWidget {
  const _ToothDialog({required this.tooth, this.current});

  final String tooth;
  final ToothState? current;

  static Future<_ToothDialogResult?> show(
      BuildContext context, String tooth, ToothState? current) {
    return showDialog<_ToothDialogResult>(
      context: context,
      builder: (_) => _ToothDialog(tooth: tooth, current: current),
    );
  }

  @override
  State<_ToothDialog> createState() => _ToothDialogState();
}

class _ToothDialogState extends State<_ToothDialog> {
  late ToothStatus _status = widget.current?.status ?? ToothStatus.sano;
  late final _note = TextEditingController(text: widget.current?.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pieza ${widget.tooth}'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            DropdownButtonFormField<ToothStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: [
                for (final s in ToothStatus.values)
                  DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: s == ToothStatus.sano
                                ? Colors.transparent
                                : s.color,
                            border: s == ToothStatus.sano
                                ? Border.all(color: Colors.grey)
                                : null,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(s.label),
                      ],
                    ),
                  ),
              ],
              onChanged: (s) =>
                  setState(() => _status = s ?? ToothStatus.sano),
            ),
            TextFormField(
              controller: _note,
              decoration:
                  const InputDecoration(labelText: 'Nota (opcional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ToothDialogResult(
            _status,
            _note.text.trim().isEmpty ? null : _note.text.trim(),
          )),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
