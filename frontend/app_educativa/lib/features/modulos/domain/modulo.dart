class Modulo {
  final String id;
  final String nombre;
  final String area;
  final int grado;
  final String descripcion;
  final String archivo;
  final bool habilitado;

  const Modulo({
    required this.id,
    required this.nombre,
    required this.area,
    required this.grado,
    required this.descripcion,
    required this.archivo,
    required this.habilitado,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'area': area,
      'grado': grado,
      'descripcion': descripcion,
      'archivo': archivo,
      'habilitado': habilitado ? 1 : 0,
    };
  }

  factory Modulo.fromMap(Map<String, dynamic> map) {
    return Modulo(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      area: map['area'] as String,
      grado: map['grado'] as int,
      descripcion: map['descripcion'] as String,
      archivo: map['archivo'] as String,
      habilitado: map['habilitado'] == 1,
    );
  }
}