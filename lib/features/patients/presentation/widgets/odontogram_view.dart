import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/odontogram_repository.dart';
import '../../domain/entities/tooth_state.dart';

final _dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm');
final _dateFmt = DateFormat('dd/MM/yyyy');

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
  List<ToothChange> _history = [];
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
      final history = await _repo.history(widget.patientId);
      if (!mounted) return;
      setState(() {
        _teeth = teeth;
        _history = history;
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
    final history = await _repo.history(widget.patientId, tooth: tooth);
    if (!mounted) return;
    final result = await _ToothDialog.show(context, tooth, current, history);
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
                padding: const EdgeInsets.only(bottom: 6),
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
                    Expanded(
                      child: Text('Pieza ${t.tooth} - ${t.status.label}'
                          '${t.note == null || t.note!.isEmpty ? '' : ' · ${t.note}'}'),
                    ),
                    if (t.updatedAt != null)
                      Text(
                        _dateFmt.format(t.updatedAt!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
          // Historial de cambios del odontograma
          Text('Historial de cambios (${_history.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_history.isEmpty)
            Text('Aun no se ha registrado ningun cambio.',
                style: Theme.of(context).textTheme.bodySmall)
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    for (final h in _history.take(30))
                      _ChangeRow(change: h),
                  ],
                ),
              ),
            ),
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

/// Una linea del historial: pieza, cambio de estado, autor y fecha.
class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.change});

  final ToothChange change;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            padding: const EdgeInsets.symmetric(vertical: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: change.status.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              change.tooth,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: change.status.color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(change.previousStatus.label,
                        style: Theme.of(context).textTheme.bodySmall),
                    const Icon(Icons.arrow_forward, size: 13),
                    Text(
                      change.status.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: change.status.color,
                          ),
                    ),
                  ],
                ),
                if (change.note != null && change.note!.isNotEmpty)
                  Text(change.note!,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_dateTimeFmt.format(change.changedAt),
                  style: Theme.of(context).textTheme.bodySmall),
              if (change.userName != null)
                Text(change.userName!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
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
  const _ToothDialog({
    required this.tooth,
    this.current,
    this.history = const [],
  });

  final String tooth;
  final ToothState? current;
  final List<ToothChange> history;

  static Future<_ToothDialogResult?> show(
    BuildContext context,
    String tooth,
    ToothState? current,
    List<ToothChange> history,
  ) {
    return showDialog<_ToothDialogResult>(
      context: context,
      builder: (_) =>
          _ToothDialog(tooth: tooth, current: current, history: history),
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
              isExpanded: true,
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
                        Flexible(
                          child: Text(s.label,
                              overflow: TextOverflow.ellipsis, maxLines: 1),
                        ),
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
            if (widget.current?.updatedAt != null)
              Text(
                'Ultima actualizacion: '
                '${_dateTimeFmt.format(widget.current!.updatedAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (widget.history.isNotEmpty) ...[
              const Divider(),
              Text('Historial de esta pieza (${widget.history.length})',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final h in widget.history)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: h.status.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${h.previousStatus.label} → ${h.status.label}',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              Text(_dateFmt.format(h.changedAt),
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
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
