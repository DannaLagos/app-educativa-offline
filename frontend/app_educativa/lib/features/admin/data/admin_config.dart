// Solo se usan al crear la base; cámbialas con --dart-define=ADMIN_USUARIO=... y ADMIN_PASSWORD=...
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
