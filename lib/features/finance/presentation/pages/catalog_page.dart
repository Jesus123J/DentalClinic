import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/deactivate_dialog.dart';
import '../../data/repositories/finance_repository.dart';
import '../../domain/entities/finance_models.dart';
import '../widgets/charts.dart';

/// Catalogo de servicios con precios y registro de gastos (dos pestanas).
class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Servicios y gastos',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(icon: Icon(Icons.medical_services_outlined),
                    text: 'Catalogo de servicios'),
                Tab(icon: Icon(Icons.receipt_outlined), text: 'Gastos'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [_TreatmentsTab(), _ExpensesTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreatmentsTab extends StatefulWidget {
  const _TreatmentsTab();

  @override
  State<_TreatmentsTab> createState() => _TreatmentsTabState();
}

class _TreatmentsTabState extends State<_TreatmentsTab> {
  final _repo = FinanceRepository();
  List<Treatment> _items = [];
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
      final items = await _repo.treatments();
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

  Future<void> _edit([Treatment? current]) async {
    final saved = await showDialog<Treatment>(
      context: context,
      builder: (_) => _TreatmentDialog(current: current),
    );
    if (saved == null) return;
    await _repo.saveTreatment(saved);
    _load();
  }

  Future<void> _delete(Treatment t) async {
    final reason = await DeactivateDialog.show(
      context,
      title: 'Dar de baja servicio',
      itemLabel: '${t.name} - ${formatMoney(t.price)}',
    );
    if (reason == null) return;
    try {
      await _repo.deleteTreatment(t.id!, reason: reason);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo dar de baja: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Estos servicios y precios aparecen al registrar un cobro.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo servicio'),
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
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Agrega tu primer servicio.'));
    }
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth < 640
            ? 1
            : c.maxWidth < 1000
                ? 2
                : 3;
        final width = (c.maxWidth - (columns - 1) * 16) / columns;
        return SingleChildScrollView(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final t in _items)
                SizedBox(
                  width: width,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) =>
                                    v == 'editar' ? _edit(t) : _delete(t),
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                      value: 'editar', child: Text('Editar')),
                                  PopupMenuItem(
                                      value: 'quitar', child: Text('Quitar')),
                                ],
                              ),
                            ],
                          ),
                          if (t.description != null &&
                              t.description!.isNotEmpty)
                            Text(
                              t.description!,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 12),
                          Text(
                            formatMoney(t.price),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: ChartColors.income(context),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TreatmentDialog extends StatefulWidget {
  const _TreatmentDialog({this.current});

  final Treatment? current;

  @override
  State<_TreatmentDialog> createState() => _TreatmentDialogState();
}

class _TreatmentDialogState extends State<_TreatmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.current?.name);
  late final _description =
      TextEditingController(text: widget.current?.description);
  late final _price = TextEditingController(
      text: widget.current?.price.toStringAsFixed(2) ?? '');

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.current == null ? 'Nuevo servicio' : 'Editar servicio'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              TextFormField(
                controller: _name,
                decoration:
                    const InputDecoration(labelText: 'Nombre del servicio *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                    labelText: 'Descripcion (opcional)'),
              ),
              TextFormField(
                controller: _price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Precio *', prefixText: 'S/ '),
                validator: (v) {
                  final value = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (value == null || value < 0) return 'Precio invalido';
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
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(Treatment(
              id: widget.current?.id,
              name: _name.text.trim(),
              description: _description.text.trim().isEmpty
                  ? null
                  : _description.text.trim(),
              price:
                  double.parse(_price.text.replaceAll(',', '.')),
            ));
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _ExpensesTab extends StatefulWidget {
  const _ExpensesTab();

  @override
  State<_ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<_ExpensesTab> {
  final _repo = FinanceRepository();
  late DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late DateTime _to = DateTime.now();
  List<Expense> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _repo.expenses(_from, _to);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
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

  Future<void> _add() async {
    final saved = await showDialog<Expense>(
      context: context,
      builder: (_) => const _ExpenseDialog(),
    );
    if (saved == null) return;
    await _repo.createExpense(saved);
    _load();
  }

  Future<void> _delete(Expense e) async {
    final reason = await DeactivateDialog.show(
      context,
      title: 'Dar de baja gasto',
      itemLabel: '${e.concept} - ${formatMoney(e.amount)}',
    );
    if (reason == null) return;
    try {
      await _repo.deleteExpense(e.id!, reason: reason);
      _load();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo dar de baja: $err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final total = _items.fold<double>(0, (a, e) => a + e.amount);
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
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: Text('${fmt.format(_from)} - ${fmt.format(_to)}'),
              ),
              Chip(
                avatar: const Icon(Icons.trending_down, size: 18),
                label: Text('Total: ${formatMoney(total)}'),
              ),
              FilledButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo gasto'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('Sin gastos en el periodo.'))
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final e = _items[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: ChartColors.expense(context)
                                    .withValues(alpha: 0.14),
                                child: Icon(Icons.receipt_outlined,
                                    size: 20,
                                    color: ChartColors.expense(context)),
                              ),
                              title: Text(e.concept),
                              subtitle: Text(
                                  '${e.category}  ·  ${fmt.format(e.spentAt)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(formatMoney(e.amount),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _delete(e),
                                  ),
                                ],
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

class _ExpenseDialog extends StatefulWidget {
  const _ExpenseDialog();

  @override
  State<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<_ExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _concept = TextEditingController();
  final _amount = TextEditingController();
  String _category = kExpenseCategories.first;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _concept.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo gasto'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              TextFormField(
                controller: _concept,
                decoration: const InputDecoration(
                    labelText: 'Concepto *',
                    hintText: 'Ej. compra de resina dental'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: [
                  for (final c in kExpenseCategories)
                    DropdownMenuItem(
                      value: c,
                      child: Text(c, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (c) =>
                    setState(() => _category = c ?? kExpenseCategories.first),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amount,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Monto *', prefixText: 'S/ '),
                      validator: (v) {
                        final value =
                            double.tryParse((v ?? '').replaceAll(',', '.'));
                        if (value == null || value <= 0) return 'Monto invalido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                      icon: const Icon(Icons.event),
                      label: Text(DateFormat('dd/MM/yyyy').format(_date)),
                    ),
                  ),
                ],
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
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(Expense(
              concept: _concept.text.trim(),
              category: _category,
              amount: double.parse(_amount.text.replaceAll(',', '.')),
              spentAt: _date,
            ));
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
