/// Lo que informa una actividad o juego (HU07) al terminar.
class ResultadoActividad {
  final String moduloId;
  final String actividadId;
  final bool completada;

  /// De 0 a 100.
  final int puntaje;

  const ResultadoActividad({
    required this.moduloId,
    required this.actividadId,
    required this.completada,
    required this.puntaje,
  }) : assert(puntaje >= 0 && puntaje <= 100);
}
