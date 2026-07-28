import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../patients/data/repositories/patient_repository_impl.dart';
import '../../../patients/domain/entities/patient.dart';
import '../../data/repositories/finance_repository.dart';
import '../../domain/entities/finance_models.dart';
import '../widgets/charts.dart';

/// Cobros: lista de ventas del periodo y registro de nuevos cobros.
class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final _repo = FinanceRepository();

  late DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late DateTime _to = DateTime.now();
  List<Sale> _sales = [];
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
      final sales = await _repo.sales(_from, _to);
      if (!mounted) return;
      setState(() {
        _sales = sales;
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

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = picked.end;
      });
      _load();
    }
  }

  Future<void> _newSale() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _NewSaleDialog(repo: _repo),
    );
    if (created == true) _load();
  }

  Future<void> _showDetail(Sale sale) async {
    final full = await _repo.saleDetail(sale.id);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cobro #${full.id}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(full.patientName ?? 'Sin paciente',
                  style: Theme.of(context).textTheme.titleSmall),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(full.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(height: 24),
              for (final i in full.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text('${i.qty}x  ${i.name}')),
                      Text(formatMoney(i.subtotal)),
                    ],
                  ),
                ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: Theme.of(context).textTheme.titleMedium),
                  Text(formatMoney(full.total),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Metodo: ${full.method.label}  ·  Estado: ${full.status}',
                  style: Theme.of(context).textTheme.bodySmall),
              if (full.note != null && full.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Nota: ${full.note}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _void(Sale sale) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anular cobro'),
        content: Text(
            'El cobro #${sale.id} por ${formatMoney(sale.total)} quedara anulado '
            'y dejara de sumar en los reportes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _repo.voidSale(sale.id);
    _load();
  }

  Color _statusColor(String status) => switch (status) {
        'pagado' => const Color(0xFF0CA30C),
        'pendiente' => const Color(0xFFFAB219),
        _ => const Color(0xFFD03B3B),
      };

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final total = _sales
        .where((s) => s.status != 'anulado')
        .fold<double>(0, (a, s) => a + s.total);
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
              Text('Cobros', style: Theme.of(context).textTheme.headlineMedium),
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: Text('${fmt.format(_from)} - ${fmt.format(_to)}'),
              ),
              Chip(
                avatar: const Icon(Icons.payments_outlined, size: 18),
                label: Text('Total: ${formatMoney(total)}'),
              ),
              FilledButton.icon(
                onPressed: _newSale,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo cobro'),
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
    if (_sales.isEmpty) {
      return const Center(child: Text('Sin cobros en este periodo.'));
    }
    return ListView.separated(
      itemCount: _sales.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final s = _sales[index];
        final anulado = s.status == 'anulado';
        return Card(
          child: ListTile(
            onTap: () => _showDetail(s),
            leading: CircleAvatar(
              backgroundColor: _statusColor(s.status).withValues(alpha: 0.14),
              child: Icon(Icons.receipt_long_outlined,
                  color: _statusColor(s.status), size: 20),
            ),
            title: Text(
              s.patientName ?? 'Sin paciente',
              style: TextStyle(
                decoration: anulado ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
                '${DateFormat('dd/MM/yyyy HH:mm').format(s.createdAt)}  ·  ${s.method.label}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(formatMoney(s.total),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(s.status,
                        style: TextStyle(
                            fontSize: 11, color: _statusColor(s.status))),
                  ],
                ),
                if (!anulado)
                  IconButton(
                    tooltip: 'Anular',
                    icon: const Icon(Icons.block, size: 20),
                    onPressed: () => _void(s),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Dialogo de nuevo cobro: paciente + servicios del catalogo.
class _NewSaleDialog extends StatefulWidget {
  const _NewSaleDialog({required this.repo});

  final FinanceRepository repo;

  @override
  State<_NewSaleDialog> createState() => _NewSaleDialogState();
}

class _NewSaleDialogState extends State<_NewSaleDialog> {
  final _patientRepo = PatientRepositoryImpl();
  final _note = TextEditingController();

  List<Patient> _patients = [];
  List<Treatment> _catalog = [];
  Patient? _patient;
  final List<SaleItem> _items = [];
  PaymentMethod _method = PaymentMethod.efectivo;
  bool _pending = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final patients = await _patientRepo.getAll();
    final catalog = await widget.repo.treatments();
    if (!mounted) return;
    setState(() {
      _patients = patients;
      _catalog = catalog;
    });
  }

  double get _total => _items.fold(0, (a, i) => a + i.subtotal);

  void _add(Treatment t) {
    final index = _items.indexWhere((i) => i.treatmentId == t.id);
    setState(() {
      if (index >= 0) {
        _items[index] = _items[index].copyWith(qty: _items[index].qty + 1);
      } else {
        _items.add(SaleItem(
            treatmentId: t.id, name: t.name, price: t.price, qty: 1));
      }
    });
  }

  Future<void> _save() async {
    if (_items.isEmpty) {
      setState(() => _error = 'Agrega al menos un servicio');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repo.createSale(
        patientId: _patient?.id,
        items: _items,
        method: _method,
        status: _pending ? 'pendiente' : 'pagado',
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'No se pudo registrar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo cobro'),
      content: SizedBox(
        width: 720,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            DropdownButtonFormField<Patient>(
              initialValue: _patient,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Paciente (opcional)'),
              items: [
                for (final p in _patients)
                  DropdownMenuItem(
                    value: p,
                    child: Text(p.fullName,
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
              ],
              onChanged: (p) => setState(() => _patient = p),
            ),
            SizedBox(
              height: 260,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Catalogo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Servicios',
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Card(
                            child: _catalog.isEmpty
                                ? const Center(
                                    child: Text('Catalogo vacio',
                                        textAlign: TextAlign.center))
                                : ListView.builder(
                                    itemCount: _catalog.length,
                                    itemBuilder: (context, i) {
                                      final t = _catalog[i];
                                      return ListTile(
                                        dense: true,
                                        title: Text(t.name,
                                            overflow: TextOverflow.ellipsis),
                                        trailing: Text(formatMoney(t.price)),
                                        onTap: () => _add(t),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Carrito
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Detalle del cobro',
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Card(
                            child: _items.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                          'Toca un servicio para agregarlo',
                                          textAlign: TextAlign.center),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _items.length,
                                    itemBuilder: (context, i) {
                                      final it = _items[i];
                                      return ListTile(
                                        dense: true,
                                        title: Text(it.name,
                                            overflow: TextOverflow.ellipsis),
                                        subtitle:
                                            Text(formatMoney(it.subtotal)),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                  size: 18),
                                              onPressed: () => setState(() {
                                                if (it.qty > 1) {
                                                  _items[i] = it.copyWith(
                                                      qty: it.qty - 1);
                                                } else {
                                                  _items.removeAt(i);
                                                }
                                              }),
                                            ),
                                            Text('${it.qty}'),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.add_circle_outline,
                                                  size: 18),
                                              onPressed: () => setState(() =>
                                                  _items[i] = it.copyWith(
                                                      qty: it.qty + 1)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<PaymentMethod>(
                    initialValue: _method,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Metodo de pago'),
                    items: [
                      for (final m in PaymentMethod.values)
                        DropdownMenuItem(value: m, child: Text(m.label)),
                    ],
                    onChanged: (m) =>
                        setState(() => _method = m ?? PaymentMethod.efectivo),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Queda pendiente'),
                    value: _pending,
                    onChanged: (v) => setState(() => _pending = v),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
            ),
            if (_error != null)
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ChartColors.income(context).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total a cobrar',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    formatMoney(_total),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
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
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Registrar cobro'),
        ),
      ],
    );
  }
}
