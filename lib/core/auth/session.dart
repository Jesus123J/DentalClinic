/// Sesion del usuario autenticado (en memoria).
class Session {
  Session._();

  static String? token;
  static String? username;
  static String? fullName;
  static String? role;

  /// Permisos efectivos que la API concedio a este rol.
  static Set<String> permissions = {};

  static bool get isLoggedIn => token != null;

  /// True si el usuario puede realizar la accion indicada.
  static bool can(String permission) => permissions.contains(permission);

  static String get roleLabel => switch (role) {
        'sistemas' => 'Ingeniero de sistemas',
        'admin' => 'Administrador',
        'odontologo' => 'Odontologo',
        'recepcion' => 'Recepcion',
        _ => role ?? '',
      };

  static void set({
    required String newToken,
    required String newUsername,
    required String newFullName,
    required String newRole,
    Set<String> newPermissions = const {},
  }) {
    token = newToken;
    username = newUsername;
    fullName = newFullName;
    role = newRole;
    permissions = newPermissions;
  }

  static void clear() {
    token = null;
    username = null;
    fullName = null;
    role = null;
    permissions = {};
  }
}
