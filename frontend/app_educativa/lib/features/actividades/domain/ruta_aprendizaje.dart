import '../../progreso/domain/progreso_modulo.dart';
import 'actividad.dart';

/// Estrellas según el puntaje (0 a 100) de una actividad.
int estrellasPorPuntaje(int puntaje) {
  if (puntaje >= 90) {
    return 3;
  }
  if (puntaje >= 60) {
    return 2;
  }

  return 1;
}

/// Puntaje de 0 a 100 al terminar una actividad. Los niños siempre terminan
/// (pueden reintentar hasta acertar), así que los errores solo bajan el
/// puntaje, nunca impiden avanzar.
int calcularPuntaje({required int aciertos, required int errores}) {
  if (aciertos <= 0) {
    return 0;
  }

  return (aciertos * 100 / (aciertos + errores)).round();
}

enum EstadoActividad {
  /// Todavía no: primero hay que terminar la anterior.
  bloqueada,

  /// Es la siguiente que toca jugar.
  disponible,

  /// Ya se jugó; se puede repetir para mejorar las estrellas.
  completada,
}

class PasoRuta {
  final Nivel nivel;
  final Actividad actividad;
  final EstadoActividad estado;

  /// 0 si nunca se ha completado.
  final int estrellas;

  const PasoRuta({
    required this.nivel,
    required this.actividad,
    required this.estado,
    required this.estrellas,
  });

  bool get sePuedeJugar => estado != EstadoActividad.bloqueada;
}

class NivelEnRuta {
  final Nivel nivel;
  final List<PasoRuta> pasos;

  const NivelEnRuta({required this.nivel, required this.pasos});

  bool get estaDesbloqueado => pasos.isNotEmpty && pasos.first.sePuedeJugar;

  bool get estaCompletado =>
      pasos.every((paso) => paso.estado == EstadoActividad.completada);

  int get estrellas => pasos.fold(0, (total, paso) => total + paso.estrellas);

  int get estrellasPosibles => pasos.length * 3;
}

/// Camino de aprendizaje: las actividades se desbloquean en orden, una
/// detrás de otra, para que el niño avance de lo fácil a lo difícil y de lo
/// más cercano (yo, mi familia) a lo más lejano (mi región, Colombia).
class RutaAprendizaje {
  final List<NivelEnRuta> niveles;

  const RutaAprendizaje._(this.niveles);

  factory RutaAprendizaje.calcular(
    PlanActividades plan,
    ProgresoModulo progreso,
  ) {
    var anteriorCompletada = true;
    final niveles = <NivelEnRuta>[];

    for (final nivel in plan.niveles) {
      final pasos = <PasoRuta>[];

      for (final actividad in nivel.actividades) {
        final guardado = progreso.actividadDe(actividad.id);
        final completada = guardado?.completada ?? false;

        final estado = completada
            ? EstadoActividad.completada
            : anteriorCompletada
                ? EstadoActividad.disponible
                : EstadoActividad.bloqueada;

        pasos.add(
          PasoRuta(
            nivel: nivel,
            actividad: actividad,
            estado: estado,
            estrellas: completada ? estrellasPorPuntaje(guardado!.puntaje) : 0,
          ),
        );

        // Una actividad completada abre la siguiente aunque alguna anterior
        // se haya agregado después (por ejemplo, en una versión nueva).
        anteriorCompletada = completada;
      }

      niveles.add(NivelEnRuta(nivel: nivel, pasos: pasos));
    }

    return RutaAprendizaje._(niveles);
  }

  List<PasoRuta> get pasos => [
        for (final nivel in niveles) ...nivel.pasos,
      ];

  int get totalActividades => pasos.length;

  int get actividadesCompletadas => pasos
      .where((paso) => paso.estado == EstadoActividad.completada)
      .length;

  /// La actividad que el niño debería jugar ahora, o null si terminó todo.
  PasoRuta? get siguiente {
    for (final paso in pasos) {
      if (paso.estado == EstadoActividad.disponible) {
        return paso;
      }
    }

    return null;
  }

  /// La actividad que viene después de [actividadId] en el camino.
  PasoRuta? despuesDe(String actividadId) {
    final lista = pasos;

    for (var indice = 0; indice < lista.length - 1; indice++) {
      if (lista[indice].actividad.id == actividadId) {
        return lista[indice + 1];
      }
    }

    return null;
  }
}
