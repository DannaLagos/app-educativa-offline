import '../../mascota/domain/mascota.dart';

class PerfilEstudiante {
  final String id;
  final String nombre;

  /// null en los perfiles creados antes de que existieran las mascotas.
  final EspecieMascota? mascota;

  /// Nombre que el niño le puso a su mascota (null si no le puso).
  final String? nombreMascota;

  const PerfilEstudiante({
    required this.id,
    required this.nombre,
    this.mascota,
    this.nombreMascota,
  });

  /// La mascota con su nombre, o null si todavía no eligió una.
  MascotaElegida? get mascotaElegida {
    final especie = mascota;

    return especie == null ? null : MascotaElegida.de(especie, nombreMascota);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'mascota': mascota?.name,
      'nombre_mascota': nombreMascota,
    };
  }

  factory PerfilEstudiante.fromMap(Map<String, dynamic> map) {
    return PerfilEstudiante(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      mascota: EspecieMascota.desdeId(map['mascota'] as String?),
      nombreMascota: map['nombre_mascota'] as String?,
    );
  }
}
