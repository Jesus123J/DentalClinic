/// Sesion del usuario autenticado (en memoria).
class Session {
  Session._();

  static String? token;
  static String? username;
  static String? fullName;
  static String? role;

  static bool get isLoggedIn => token != null;

  static void set({
    required String newToken,
    required String newUsername,
    required String newFullName,
    required String newRole,
  }) {
    token = newToken;
    username = newUsername;
    fullName = newFullName;
    role = newRole;
  }

  static void clear() {
    token = null;
    username = null;
    fullName = null;
    role = null;
  }
}
