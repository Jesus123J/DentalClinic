import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/session.dart';
import '../../data/repositories/audit_repository.dart';
import '../../domain/entities/audit_entry.dart';

/// Auditoria: bitacora de operaciones y papelera de registros dados de baja.
class AuditPage extends StatelessWidget {
  const AuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final canSeeTrash = Session.can('trash.view');
    return DefaultTabController(
      length: canSeeTrash ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Auditoria',
                style: Theme.of(context).textTheme.headlineMedium),
            Text(
              'Toda operacion queda registrada con el usuario, su rol, la '
              'fecha y el motivo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                const Tab(
                    icon: Icon(Icons.history), text: 'Registro de operaciones'),
                if (canSeeTrash)
                  const Tab(
                      icon: Icon(Icons.inventory_2_outlined),
                      text: 'Papelera (dados de baja)'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const _AuditLogTab(),
                  if (canSeeTrash) const _TrashTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditLogTab extends StatefulWidget {
  const _AuditLogTab();

  @override
  State<_AuditLogTab> createState() => _AuditLogTabState();
}

class _AuditLogTabState extends State<_AuditLogTab> {
  final _repo = AuditRepository();
  final _userFilter = TextEditingController();
  List<AuditEntry> _entries = [];
  bool _loading = true;
  String? _error;
  String? _entity;

  static final _fmt = DateFormat('dd/MM/yyyy HH:mm');

  static const _entities = [
    'paciente', 'cita', 'registro clinico', 'archivo adjunto',
    'cobro', 'gasto', 'servicio', 'usuario', 'sesion',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _userFilter.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await _repo.entries(
        entity: _entity,
        user: _userFilter.text.trim().isEmpty ? null : _userFilter.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar: $e';
        _loading = false;
      });
    }
  }

  Color _actionColor(String action) => switch (action) {
        'crear' => const Color(0xFF0CA30C),
        'editar' => const Color(0xFF2A78D6),
        'desactivar' || 'anular' || 'deshabilitar' => const Color(0xFFD03B3B),
        'reactivar' || 'habilitar' => const Color(0xFFD9A521),
        'registrar pago' => const Color(0xFF1BAF7A),
        _ => const Color(0xFF898781),
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<String?>(
                  initialValue: _entity,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Tipo de registro', isDense: true),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    for (final e in _entities)
                      DropdownMenuItem(value: e, child: Text(e)),
                  ],
                  onChanged: (v) {
                    setState(() => _entity = v);
                    _load();
                  },
                ),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _userFilter,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    isDense: true,
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
              Text('${_entries.length} operaciones',
                  style: Theme.of(context).textTheme.bodySmall),
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
    if (_entries.isEmpty) {
      return const Center(child: Text('Sin operaciones registradas.'));
    }
    return ListView.separated(
      itemCount: _entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final e = _entries[i];
        final color = _actionColor(e.action);
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    e.action,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.entity}${e.entityId == null ? '' : ' #${e.entityId}'}'
                        '${e.description == null ? '' : ' - ${e.description}'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (e.reason != null && e.reason!.isNotEmpty)
                        Text('Motivo: ${e.reason}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(e.userName,
                        style: Theme.of(context).textTheme.bodySmall),
                    Text('${e.userRole} · ${_fmt.format(e.createdAt)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 11)),
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

/// Papelera: registros ocultos que solo el ingeniero de sistemas ve.
class _TrashTab extends StatefulWidget {
  const _TrashTab();

  @override
  State<_TrashTab> createState() => _TrashTabState();
}

class _TrashTabState extends State<_TrashTab> {
  final _repo = AuditRepository();
  List<TrashEntry> _items = [];
  bool _loading = true;
  String? _error;

  static final _fmt = DateFormat('dd/MM/yyyy HH:mm');

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
      final items = await _repo.trash();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar: $e';
        _loading = false;
      });
    }
  }

  Future<void> _restore(TrashEntry entry) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactivar registro'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${entry.entity}: ${entry.label}',
                  style: Theme.of(context).textTheme.titleSmall),
              if (entry.reason != null) ...[
                const SizedBox(height: 8),
                Text('Se dio de baja por: ${entry.reason}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: 'Motivo de la reactivacion *'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    try {
      await _repo.restore(entry, reason);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo reactivar: $e')));
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
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estos registros no se muestran en el sistema pero siguen '
            'guardados. Solo tu puedes devolverlos.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('La papelera esta vacia.'))
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final t = _items[i];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.inventory_2_outlined, size: 20),
                          ),
                          title: Text(t.label),
                          subtitle: Text([
                            t.entity,
                            if (t.deactivatedAt != null)
                              _fmt.format(t.deactivatedAt!),
                            if (t.deactivatedBy != null) 'por ${t.deactivatedBy}',
                            if (t.reason != null) 'motivo: ${t.reason}',
                          ].join('  ·  ')),
                          trailing: FilledButton.icon(
                            onPressed: () => _restore(t),
                            icon: const Icon(Icons.restore, size: 18),
                            label: const Text('Reactivar'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
