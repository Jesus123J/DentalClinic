import 'package:flutter/material.dart';

import '../../data/repositories/user_repository.dart';
import '../../domain/entities/app_user.dart';

/// Gestion de cuentas (solo visible para el administrador).
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _repo = UserRepository();
  List<AppUser> _users = [];
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
      final users = await _repo.getAll();
      if (!mounted) return;
      setState(() {
        _users = users;
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

  Future<void> _create() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _UserFormDialog(repo: _repo),
    );
    if (created == true) _load();
  }

  Future<void> _toggleActive(AppUser user, bool active) async {
    try {
      await _repo.setActive(user.id, active);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo cambiar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Usuarios',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.person_add),
                label: const Text('Nueva cuenta'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Las cuentas nuevas son de recepcion u odontologo; '
            'las cuentas deshabilitadas no pueden iniciar sesion.',
            style: Theme.of(context).textTheme.bodySmall,
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
    return ListView.separated(
      itemCount: _users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final u = _users[index];
        final isAdmin = u.role == 'admin';
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(isAdmin
                  ? Icons.admin_panel_settings_outlined
                  : Icons.person_outline),
            ),
            title: Text(u.fullName),
            subtitle: Text('@${u.username} — ${u.roleLabel}'),
            trailing: isAdmin
                ? const Chip(label: Text('Siempre activo'))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(u.active ? 'Habilitada' : 'Deshabilitada'),
                      const SizedBox(width: 8),
                      Switch(
                        value: u.active,
                        onChanged: (v) => _toggleActive(u, v),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({required this.repo});

  final UserRepository repo;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _fullName = TextEditingController();
  final _password = TextEditingController();
  String _role = 'recepcion';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _fullName.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repo.create(
        username: _username.text.trim(),
        password: _password.text,
        fullName: _fullName.text.trim(),
        role: _role,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().contains('409')
            ? 'Ese nombre de usuario ya existe'
            : 'No se pudo crear: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva cuenta'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullName,
                decoration:
                    const InputDecoration(labelText: 'Nombre completo *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Usuario *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Contrasena * (minimo 6 caracteres)'),
                validator: (v) =>
                    v == null || v.length < 6 ? 'Minimo 6 caracteres' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(
                      value: 'recepcion', child: Text('Recepcion')),
                  DropdownMenuItem(
                      value: 'odontologo', child: Text('Odontologo')),
                ],
                onChanged: (v) => setState(() => _role = v ?? 'recepcion'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
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
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Crear'),
        ),
      ],
    );
  }
}
