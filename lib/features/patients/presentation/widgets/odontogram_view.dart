import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/session.dart';
import '../../data/repositories/odontogram_repository.dart';
import '../../domain/entities/tooth_state.dart';
import 'tooth_widget.dart';

final _dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm');
final _dateFmt = DateFormat('dd/MM/yyyy');

/// Odontograma segun la norma tecnica NTS 150-MINSA-2019:
/// denticion permanente y decidua, con registro por pieza y por cara.
class OdontogramView extends StatefulWidget {
  const OdontogramView({super.key, required this.patientId});

  final int patientId;

  @override
  State<OdontogramView> createState() => _OdontogramViewState();
}

class _OdontogramViewState extends State<OdontogramView> {
  final _repo = OdontogramRepository();
  final _specifications = TextEditingController();
  final _observations = TextEditingController();

  Map<String, ToothState> _teeth = {};
  List<ToothChange> _history = [];
  bool _loading = true;
  bool _showDeciduous = false;
  String? _error;

  bool get _canEdit => Session.can('clinical.edit');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _specifications.dispose();
    _observations.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final teeth = await _repo.getByPatient(widget.patientId);
      final history = await _repo.history(widget.patientId);
      final notes = await _repo.notes(widget.patientId);
      if (!mounted) return;
      setState(() {
        _teeth = teeth;
        _history = history;
        _specifications.text = notes.specifications ?? '';
        _observations.text = notes.observations ?? '';
        // Si el paciente ya tiene piezas deciduas registradas, se muestran
        _showDeciduous = _showDeciduous ||
            teeth.values.any((t) => t.isDeciduous);
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

  Future<void> _editSurface(String tooth, ToothSurface surface) async {
    if (!_canEdit) return;
    final current = _teeth[OdontogramRepository.key(tooth, surface)];
    final history = await _repo.history(widget.patientId, tooth: tooth);
    if (!mounted) return;
    final result =
        await _ToothDialog.show(context, tooth, surface, current, history);
    if (result == null) return;
    try {
      await _repo.save(ToothState(
        patientId: widget.patientId,
        tooth: tooth,
        surface: result.surface,
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

  Future<void> _saveNotes() async {
    try {
      await _repo.saveNotes(
        widget.patientId,
        OdontogramNotes(
          specifications: _specifications.text.trim().isEmpty
              ? null
              : _specifications.text.trim(),
          observations: _observations.text.trim().isEmpty
              ? null
              : _observations.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notas del odontograma guardadas')),
      );
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

    final findings = _teeth.values.toList()
      ..sort((a, b) => a.tooth.compareTo(b.tooth));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _canEdit
                      ? 'Toca una cara del diente para registrar su estado '
                          '(centro = oclusal). Norma tecnica NTS 150-MINSA-2019.'
                      : 'Odontograma del paciente (solo lectura).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              FilterChip(
                label: const Text('Denticion decidua'),
                selected: _showDeciduous,
                onSelected: (v) => setState(() => _showDeciduous = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLegend(),
          const SizedBox(height: 16),
          _buildChart(),
          const SizedBox(height: 16),
          _buildNotes(),
          const SizedBox(height: 16),
          if (findings.isNotEmpty) ...[
            Text('Hallazgos registrados (${findings.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final t in findings)
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
                      child: Text(
                        'Pieza ${t.tooth}'
                        '${t.surface == ToothSurface.completa ? '' : ' (${t.surface.label})'}'
                        ' - ${t.status.label}'
                        '${t.note == null || t.note!.isEmpty ? '' : ' · ${t.note}'}',
                      ),
                    ),
                    if (t.updatedAt != null)
                      Text(_dateFmt.format(t.updatedAt!),
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
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
                    for (final h in _history.take(30)) _ChangeRow(change: h),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in ToothStatus.values)
          if (s != ToothStatus.sano)
            Chip(
              avatar: CircleAvatar(backgroundColor: s.color),
              label: Text(s.label, style: const TextStyle(fontSize: 12)),
              visualDensity: VisualDensity.compact,
            ),
      ],
    );
  }

  /// Grafico con el orden del formato oficial: permanente superior,
  /// decidua superior, decidua inferior y permanente inferior.
  Widget _buildChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: [
              _arch(kUpperTeeth, labelOnTop: true, split: 8),
              if (_showDeciduous) ...[
                const SizedBox(height: 14),
                _arch(kUpperDeciduous, labelOnTop: true, split: 5),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(width: 640, child: Divider(thickness: 1.2)),
              ),
              if (_showDeciduous) ...[
                _arch(kLowerDeciduous, labelOnTop: false, split: 5),
                const SizedBox(height: 14),
              ],
              _arch(kLowerTeeth, labelOnTop: false, split: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _arch(List<String> teeth,
      {required bool labelOnTop, required int split}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < teeth.length; i++) ...[
          if (i == split)
            Container(
              width: 1.2,
              height: 44,
              color: Theme.of(context).dividerColor,
              margin: const EdgeInsets.symmetric(horizontal: 6),
            ),
          ToothWidget(
            tooth: teeth[i],
            states: _teeth,
            labelOnTop: labelOnTop,
            onTapSurface: _editSurface,
          ),
        ],
      ],
    );
  }

  Widget _buildNotes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _specifications,
              readOnly: !_canEdit,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Especificaciones',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _observations,
              readOnly: !_canEdit,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                isDense: true,
              ),
            ),
            if (_canEdit) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _saveNotes,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Guardar notas'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Una linea del historial: pieza, cara, cambio de estado, autor y fecha.
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
                    if (change.surface != ToothSurface.completa)
                      Text('${change.surface.label}:',
                          style: Theme.of(context).textTheme.bodySmall),
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

class _ToothDialogResult {
  const _ToothDialogResult(this.surface, this.status, this.note);
  final ToothSurface surface;
  final ToothStatus status;
  final String? note;
}

class _ToothDialog extends StatefulWidget {
  const _ToothDialog({
    required this.tooth,
    required this.surface,
    this.current,
    this.history = const [],
  });

  final String tooth;
  final ToothSurface surface;
  final ToothState? current;
  final List<ToothChange> history;

  static Future<_ToothDialogResult?> show(
    BuildContext context,
    String tooth,
    ToothSurface surface,
    ToothState? current,
    List<ToothChange> history,
  ) {
    return showDialog<_ToothDialogResult>(
      context: context,
      builder: (_) => _ToothDialog(
        tooth: tooth,
        surface: surface,
        current: current,
        history: history,
      ),
    );
  }

  @override
  State<_ToothDialog> createState() => _ToothDialogState();
}

class _ToothDialogState extends State<_ToothDialog> {
  late ToothSurface _surface = widget.surface;
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
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              DropdownButtonFormField<ToothSurface>(
                initialValue: _surface,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Cara / superficie'),
                items: [
                  for (final s in ToothSurface.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (s) =>
                    setState(() => _surface = s ?? ToothSurface.completa),
              ),
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
                onChanged: (s) => setState(() {
                  _status = s ?? ToothStatus.sano;
                  // Estos hallazgos son de toda la pieza, no de una cara
                  if (_status.isWholeTooth) _surface = ToothSurface.completa;
                }),
              ),
              if (_status.isWholeTooth)
                Text(
                  'Este hallazgo se registra sobre la pieza completa.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              TextFormField(
                controller: _note,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
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
                  constraints: const BoxConstraints(maxHeight: 160),
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
                                    '${h.surface == ToothSurface.completa ? '' : '${h.surface.label}: '}'
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ToothDialogResult(
            _surface,
            _status,
            _note.text.trim().isEmpty ? null : _note.text.trim(),
          )),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
