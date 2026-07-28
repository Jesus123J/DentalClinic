/// Una operacion registrada en la bitacora del sistema.
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.userName,
    required this.userRole,
    required this.action,
    required this.entity,
    this.entityId,
    this.description,
    this.reason,
    required this.createdAt,
  });

  final int id;
  final String userName;
  final String userRole;

  /// crear, editar, desactivar, reactivar, anular, registrar pago...
  final String action;

  /// paciente, cita, cobro, gasto, usuario...
  final String entity;

  final int? entityId;
  final String? description;

  /// Motivo indicado por el usuario (en bajas y reactivaciones).
  final String? reason;

  final DateTime createdAt;

  bool get isSensitive => const {
        'desactivar',
        'anular',
        'reactivar',
        'deshabilitar',
      }.contains(action);
}

/// Registro dado de baja que sigue guardado en la base de datos.
class TrashEntry {
  const TrashEntry({
    required this.id,
    required this.table,
    required this.entity,
    required this.label,
    this.deactivatedAt,
    this.deactivatedBy,
    this.reason,
  });

  final int id;
  final String table;
  final String entity;
  final String label;
  final DateTime? deactivatedAt;
  final String? deactivatedBy;
  final String? reason;
}
