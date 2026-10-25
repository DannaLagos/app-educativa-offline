import 'dart:convert';
import 'dart:io';

import '../../modulos/domain/recurso_local.dart';
import '../domain/actividad.dart';

/// El archivo de actividades está dañado o no tiene el formato esperado.
class ActividadesInvalidasException implements Exception {
  final String mensaje;

  const ActividadesInvalidasException(this.mensaje);

  @override
  String toString() => 'ActividadesInvalidasException: $mensaje';
}

/// Lee las actividades de un módulo descargado. Solo usa archivos del
/// dispositivo, así que funciona sin internet (HU07, criterio 2).
class ActividadesLocalDataSource {
  /// Valor de `tipo` del recurso en el manifest del módulo.
  static const String tipoRecurso = 'actividades';

  const ActividadesLocalDataSource();

  /// Devuelve null si el módulo no tiene actividades (por ejemplo, si se
  /// descargó antes de que se agregaran los juegos).
  Future<PlanActividades?> leer(List<RecursoLocal> recursos) async {
    for (final recurso in recursos) {
      if (recurso.tipo == tipoRecurso) {
        return leerArchivo(recurso.ruta);
      }
    }

    return null;
  }

  Future<PlanActividades> leerArchivo(String ruta) async {
    final String contenido;

    try {
      contenido = await File(ruta).readAsString();
    } on FileSystemException catch (error) {
      throw ActividadesInvalidasException('No se pudo leer $ruta: $error');
    }

    return interpretar(contenido);
  }

  PlanActividades interpretar(String contenido) {
    try {
      return PlanActividades.fromJson(jsonDecode(contenido));
    } on FormatException catch (error) {
      throw ActividadesInvalidasException(error.message);
    }
  }
}
