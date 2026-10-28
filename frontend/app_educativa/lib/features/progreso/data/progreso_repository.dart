import '../domain/progreso_modulo.dart';
import '../domain/resultado_actividad.dart';
import 'progreso_local_datasource.dart';

/// Se lanza cuando se intenta guardar progreso sin un perfil creado.
class SinPerfilException implements Exception {
  const SinPerfilException();

  @override
  String toString() => 'SinPerfilException: no hay un perfil de estudiante.';
}

/// Punto de entrada al progreso del estudiante (patrón Repository).
///
/// Asocia todo al perfil del estudiante (HU01), así las pantallas no tienen
/// que conocer su identificador. Hoy solo usa la base local; en la HU11 aquí
/// se agregará el envío al servidor.
class ProgresoRepository {
  final ProgresoLocalDataSource _local;
  final Future<String?> Function() _obtenerPerfilId;

  String? _perfilId;

  ProgresoRepository({
    required ProgresoLocalDataSource local,
    required Future<String?> Function() obtenerPerfilId,
  })  : _local = local,
        _obtenerPerfilId = obtenerPerfilId;

  Future<void> guardarPaginaLeida({
    required String moduloId,
    required String recurso,
    required int pagina,
    required int totalPaginas,
  }) async {
    await _local.guardarLectura(
      perfilId: await _perfilActual(),
      moduloId: moduloId,
      recurso: recurso,
      pagina: pagina,
      totalPaginas: totalPaginas,
    );
  }

  /// Lo llaman las actividades y juegos (HU07) al terminar.
  Future<void> registrarResultadoActividad(ResultadoActividad resultado) async {
    await _local.registrarResultado(
      perfilId: await _perfilActual(),
      resultado: resultado,
    );
  }

  Future<ProgresoModulo> obtenerProgresoModulo(String moduloId) async {
    final perfilId = await _buscarPerfil();

    if (perfilId == null) {
      return ProgresoModulo.vacio(moduloId);
    }

    return _local.obtenerProgresoModulo(
      perfilId: perfilId,
      moduloId: moduloId,
    );
  }

  /// Módulo en el que el estudiante avanzó por última vez (HU08).
  Future<String?> obtenerUltimoModulo() async {
    final perfilId = await _buscarPerfil();

    if (perfilId == null) {
      return null;
    }

    return _local.obtenerUltimoModuloId(perfilId);
  }

  Future<String> _perfilActual() async {
    final perfilId = await _buscarPerfil();

    if (perfilId == null) {
      throw const SinPerfilException();
    }

    return perfilId;
  }

  Future<String?> _buscarPerfil() async {
    // Solo se guarda cuando existe: el perfil puede crearse después de
    // abrir la app.
    return _perfilId ??= await _obtenerPerfilId();
  }
}
