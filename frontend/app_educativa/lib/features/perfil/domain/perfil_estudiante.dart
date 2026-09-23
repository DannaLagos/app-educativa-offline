class PerfilEstudiante {
  final String id;
  final String nombre;

  const PerfilEstudiante({
    required this.id,
    required this.nombre,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }

  factory PerfilEstudiante.fromMap(Map<String, dynamic> map) {
    return PerfilEstudiante(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
    );
  }
}