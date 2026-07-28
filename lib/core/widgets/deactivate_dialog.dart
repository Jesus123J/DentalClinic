import 'package:flutter/material.dart';

/// Dialogo de baja logica: exige un motivo y advierte que el registro
/// no se elimina, solo deja de mostrarse.
class DeactivateDialog extends StatefulWidget {
  const DeactivateDialog({
    super.key,
    required this.title,
    required this.itemLabel,
    this.actionLabel = 'Dar de baja',
  });

  /// Ej. "Dar de baja paciente".
  final String title;

  /// Ej. "Maria Gonzalez Perez".
  final String itemLabel;

  final String actionLabel;

  /// Devuelve el motivo escrito, o null si se cancelo.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String itemLabel,
    String actionLabel = 'Dar de baja',
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => DeactivateDialog(
        title: title,
        itemLabel: itemLabel,
        actionLabel: actionLabel,
      ),
    );
  }

  @override
  State<DeactivateDialog> createState() => _DeactivateDialogState();
}

class _DeactivateDialogState extends State<DeactivateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Text(widget.itemLabel,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAB219).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 20, color: Color(0xFFB8860B)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'El registro no se elimina: deja de mostrarse en el '
                        'sistema pero se conserva. Solo el ingeniero de '
                        'sistemas puede reactivarlo. Esta accion queda '
                        'registrada con tu usuario y la fecha.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              TextFormField(
                controller: _reason,
                autofocus: true,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Motivo *',
                  hintText: 'Explica por que se da de baja',
                ),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Debes indicar el motivo';
                  if (value.length < 5) return 'Describe mejor el motivo';
                  return null;
                },
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
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
          ),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(_reason.text.trim());
          },
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
