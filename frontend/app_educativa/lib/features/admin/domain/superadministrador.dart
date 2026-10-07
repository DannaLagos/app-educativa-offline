class Superadministrador {
  final String id;
  final String usuario;

  const Superadministrador({
    required this.id,
    required this.usuario,
  });

  factory Superadministrador.fromMap(Map<String, dynamic> map) {
    return Superadministrador(
      id: map['id'] as String,
      usuario: map['usuario'] as String,
    );
  }
}
