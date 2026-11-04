class Superadministrador {
  /// uid de Firebase Authentication.
  final String id;

  /// Nombre para el saludo del panel (o el correo, si no tiene nombre).
  final String usuario;

  const Superadministrador({
    required this.id,
    required this.usuario,
  });
}
