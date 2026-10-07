// Credenciales iniciales del superadministrador.
// Solo se usan la primera vez que se crea la base de datos; después la
// contraseña queda guardada como hash en SQLite.
// Para no usar la contraseña por defecto, compila con:
//   flutter run --dart-define=ADMIN_PASSWORD=<tu_contraseña>
class AdminConfig {
  AdminConfig._();

  static const String usuarioInicial = String.fromEnvironment(
    'ADMIN_USUARIO',
    defaultValue: 'admin',
  );

  static const String passwordInicial = String.fromEnvironment(
    'ADMIN_PASSWORD',
    defaultValue: 'Admin2026*',
  );
}
