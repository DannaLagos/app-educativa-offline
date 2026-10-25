import 'dart:math';

/// Página donde va el estudiante en un documento (PDF) de un módulo.
class ProgresoLectura {
  /// Nombre del archivo dentro del módulo (por ejemplo, `CS_Grado01_Fichas.pdf`).
  final String recurso;

  /// Última página abierta: desde aquí se continúa (HU08).
  final int ultimaPagina;

  /// Página más avanzada a la que ha llegado: con esta se mide el avance,
  /// para que volver atrás no reduzca el progreso.
  final int paginaMaxima;

  final int totalPaginas;
  final DateTime ultimaActualizacion;

  /// true cuando el servidor ya confirmó que lo recibió (HU11).
  final bool sincronizado;

  const ProgresoLectura({
    required this.recurso,
    required this.ultimaPagina,
    required this.paginaMaxima,
    required this.totalPaginas,
    required this.ultimaActualizacion,
    this.sincronizado = false,
  });

  /// De 0 a 1.
  double get avance =>
      totalPaginas <= 0 ? 0.0 : min(max(paginaMaxima / totalPaginas, 0.0), 1.0);

  factory ProgresoLectura.fromMap(Map<String, Object?> fila) {
    return ProgresoLectura(
      recurso: fila['recurso'] as String,
      ultimaPagina: fila['ultima_pagina'] as int,
      paginaMaxima: fila['pagina_maxima'] as int,
      totalPaginas: fila['total_paginas'] as int,
      ultimaActualizacion:
          DateTime.parse(fila['ultima_actualizacion'] as String),
      sincronizado: fila['sincronizado'] == 1,
    );
  }
}

/// Resultado guardado de una actividad o juego.
class ProgresoActividad {
  final String actividadId;
  final bool completada;

  /// Mejor puntaje obtenido (0 a 100).
  final int puntaje;
  final int intentos;
  final DateTime ultimaActualizacion;

  /// true cuando el servidor ya confirmó que lo recibió (HU11).
  final bool sincronizado;

  const ProgresoActividad({
    required this.actividadId,
    required this.completada,
    required this.puntaje,
    required this.intentos,
    required this.ultimaActualizacion,
    this.sincronizado = false,
  });

  factory ProgresoActividad.fromMap(Map<String, Object?> fila) {
    return ProgresoActividad(
      actividadId: fila['actividad_id'] as String,
      completada: fila['completada'] == 1,
      puntaje: fila['puntaje'] as int,
      intentos: fila['intentos'] as int,
      ultimaActualizacion:
          DateTime.parse(fila['ultima_actualizacion'] as String),
      sincronizado: fila['sincronizado'] == 1,
    );
  }
}

/// Todo el progreso guardado de un estudiante en un módulo.
class ProgresoModulo {
  final String moduloId;

  /// De 0 a 100.
  final int porcentaje;
  final DateTime? ultimaActualizacion;
  final List<ProgresoLectura> lecturas;
  final List<ProgresoActividad> actividades;

  const ProgresoModulo({
    required this.moduloId,
    required this.porcentaje,
    required this.ultimaActualizacion,
    required this.lecturas,
    required this.actividades,
  });

  const ProgresoModulo.vacio(this.moduloId)
      : porcentaje = 0,
        ultimaActualizacion = null,
        lecturas = const [],
        actividades = const [];

  bool get estaIniciado => lecturas.isNotEmpty || actividades.isNotEmpty;

  int get actividadesCompletadas =>
      actividades.where((actividad) => actividad.completada).length;

  ProgresoLectura? lecturaDe(String recurso) {
    for (final lectura in lecturas) {
      if (lectura.recurso == recurso) {
        return lectura;
      }
    }

    return null;
  }

  ProgresoActividad? actividadDe(String actividadId) {
    for (final actividad in actividades) {
      if (actividad.actividadId == actividadId) {
        return actividad;
      }
    }

    return null;
  }
}
