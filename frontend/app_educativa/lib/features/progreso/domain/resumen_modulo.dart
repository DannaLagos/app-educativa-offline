import '../../actividades/domain/actividad.dart';
import '../../actividades/domain/ruta_aprendizaje.dart';
import '../../modulos/domain/modulo.dart';
import 'progreso_modulo.dart';

/// Lo que el estudiante lleva en un módulo (HU09): juegos terminados y
/// pendientes, estrellas y lectura. Se calcula solo con datos del
/// dispositivo.
class ResumenModulo {
  final Modulo modulo;
  final ProgresoModulo progreso;

  /// Juegos del módulo, o null si el módulo no está descargado (entonces
  /// solo se conoce lo que ya se terminó).
  final PlanActividades? plan;

  const ResumenModulo({
    required this.modulo,
    required this.progreso,
    required this.plan,
  });

  bool get estaIniciado => progreso.estaIniciado;

  /// Camino de juegos con su estado (terminado, pendiente o bloqueado).
  RutaAprendizaje? get ruta {
    final datos = plan;

    return datos == null ? null : RutaAprendizaje.calcular(datos, progreso);
  }

  int get juegosTerminados =>
      ruta?.actividadesCompletadas ?? progreso.actividadesCompletadas;

  /// null si no se sabe cuántos juegos tiene (módulo no descargado).
  int? get juegosTotales => plan?.actividades.length;

  int get juegosPendientes => (juegosTotales ?? juegosTerminados) - juegosTerminados;

  int get estrellas {
    final camino = ruta;

    if (camino != null) {
      return camino.pasos.fold(0, (total, paso) => total + paso.estrellas);
    }

    return progreso.actividades
        .where((actividad) => actividad.completada)
        .fold(0, (total, a) => total + estrellasPorPuntaje(a.puntaje));
  }

  /// De 0 a 1, o null si no se conoce el total de juegos.
  double? get avanceJuegos {
    final total = juegosTotales;

    if (total == null || total == 0) {
      return null;
    }

    return juegosTerminados / total;
  }

  /// El documento que se leyó por última vez.
  ProgresoLectura? get lectura {
    if (progreso.lecturas.isEmpty) {
      return null;
    }

    return progreso.lecturas.reduce(
      (a, b) => a.ultimaActualizacion.isAfter(b.ultimaActualizacion) ? a : b,
    );
  }

  bool get estaTerminado =>
      juegosTotales != null && juegosTotales! > 0 && juegosPendientes == 0;
}
