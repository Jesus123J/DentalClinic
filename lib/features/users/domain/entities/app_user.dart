import 'package:equatable/equatable.dart';

/// Cuenta de usuario del sistema.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.active,
  });

  final int id;
  final String username;
  final String fullName;
  final String role;
  final bool active;

  String get roleLabel => switch (role) {
        'admin' => 'Administrador',
        'odontologo' => 'Odontologo',
        'recepcion' => 'Recepcion',
        _ => role,
      };

  @override
  List<Object?> get props => [id, username, fullName, role, active];
}
