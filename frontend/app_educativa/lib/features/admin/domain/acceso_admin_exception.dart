class AccesoAdminException implements Exception {
  static const String datosInvalidos = 'Los datos de acceso no son válidos.';
  static const String sinConexion =
      'Necesitas conexión a internet para iniciar sesión.';
  static const String demasiadosIntentos =
      'Demasiados intentos. Espera unos minutos e intenta de nuevo.';

  final String mensaje;
  final Object? causa;

  const AccesoAdminException(this.mensaje, [this.causa]);

  @override
  String toString() => 'AccesoAdminException: $mensaje ($causa)';
}
