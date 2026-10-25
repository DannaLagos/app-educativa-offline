/// Registros del progreso que todavía no se han enviado al servidor
/// (`sincronizado = 0`), tal como están en SQLite (HU10).
///
/// Mientras no se confirme el envío, estos registros siguen en el teléfono
/// marcados como pendientes: nunca se borran.
class ProgresoPendiente {
  final String perfilId;

  /// Nombre del estudiante, para que el docente lo reconozca en el servidor.
  final String? nombreEstudiante;

  final List<Map<String, Object?>> modulos;
  final List<Map<String, Object?>> lecturas;
  final List<Map<String, Object?>> actividades;

  const ProgresoPendiente({
    required this.perfilId,
    this.nombreEstudiante,
    this.modulos = const [],
    this.lecturas = const [],
    this.actividades = const [],
  });

  bool get estaVacio =>
      modulos.isEmpty && lecturas.isEmpty && actividades.isEmpty;

  /// Cuántos avances (páginas leídas o juegos) faltan por enviar. El resumen
  /// del módulo no se cuenta aparte porque cambia junto con ellos.
  int get cambios {
    final avances = lecturas.length + actividades.length;

    return avances == 0 && modulos.isNotEmpty ? modulos.length : avances;
  }

  ProgresoPendiente conNombre(String? nombre) {
    return ProgresoPendiente(
      perfilId: perfilId,
      nombreEstudiante: nombre,
      modulos: modulos,
      lecturas: lecturas,
      actividades: actividades,
    );
  }
}
