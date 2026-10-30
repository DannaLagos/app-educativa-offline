import 'package:flutter/foundation.dart';

import '../../../core/network/conectividad_service.dart';
import '../../perfil/domain/perfil_estudiante.dart';
import '../domain/progreso_modulo.dart';
import '../domain/resultado_actividad.dart';
import '../domain/resultado_sincronizacion.dart';
import 'progreso_local_datasource.dart';
import 'progreso_remote_datasource.dart';

/// Se lanza cuando se intenta guardar progreso sin un perfil creado.
class SinPerfilException implements Exception {
  const SinPerfilException();

  @override
  String toString() => 'SinPerfilException: no hay un perfil de estudiante.';
}

/// Único punto de entrada al progreso del estudiante (patrón Repository,
/// offline first):
/// - SQLite es la fuente de verdad: las pantallas siempre leen y escriben ahí,
///   con o sin internet (HU06–HU09).
/// - El servidor solo recibe una copia: [sincronizar] envía lo pendiente
///   cuando hay conexión y nunca borra nada del teléfono (HU10–HU11).
class ProgresoRepository {
  final ProgresoLocalDataSource _local;
  final ProgresoRemoteDataSource _remote;
  final ConectividadService _conectividad;
  final Future<PerfilEstudiante?> Function() _obtenerPerfil;

  PerfilEstudiante? _perfil;

  ProgresoRepository({
    required ProgresoLocalDataSource local,
    required Future<PerfilEstudiante?> Function() obtenerPerfil,
    ProgresoRemoteDataSource remote =
        const SinServidorProgresoRemoteDataSource(),
    ConectividadService? conectividad,
  })  : _local = local,
        _remote = remote,
        _conectividad = conectividad ?? ConectividadService(),
        _obtenerPerfil = obtenerPerfil;

  Future<void> guardarPaginaLeida({
    required String moduloId,
    required String recurso,
    required int pagina,
    required int totalPaginas,
  }) async {
    await _local.guardarLectura(
      perfilId: (await _perfilActual()).id,
      moduloId: moduloId,
      recurso: recurso,
      pagina: pagina,
      totalPaginas: totalPaginas,
    );
  }

  /// Lo llaman las actividades y juegos (HU07) al terminar.
  Future<void> registrarResultadoActividad(ResultadoActividad resultado) async {
    await _local.registrarResultado(
      perfilId: (await _perfilActual()).id,
      resultado: resultado,
    );
  }

  Future<ProgresoModulo> obtenerProgresoModulo(String moduloId) async {
    final perfil = await _buscarPerfil();

    if (perfil == null) {
      return ProgresoModulo.vacio(moduloId);
    }

    return _local.obtenerProgresoModulo(
      perfilId: perfil.id,
      moduloId: moduloId,
    );
  }

  /// Módulo en el que el estudiante avanzó por última vez (HU08).
  Future<String?> obtenerUltimoModulo() async {
    final perfil = await _buscarPerfil();

    return perfil == null ? null : _local.obtenerUltimoModuloId(perfil.id);
  }

  /// Cuántos avances faltan por enviar (solo lee el teléfono).
  Future<int> contarPendientes() async {
    final perfil = await _buscarPerfil();

    if (perfil == null) {
      return 0;
    }

    return (await _local.obtenerPendientes(perfil.id)).cambios;
  }

  /// Fecha del último envío correcto, guardada en SQLite (HU11).
  Future<DateTime?> ultimaSincronizacion() async {
    final perfil = await _buscarPerfil();

    return perfil == null
        ? null
        : _local.obtenerUltimaSincronizacion(perfil.id);
  }

  /// Envía al servidor lo pendiente (HU10–HU11). Un registro solo deja de
  /// estar pendiente cuando el servidor confirma que lo recibió.
  Future<ResultadoSincronizacion> sincronizar() async {
    final perfil = await _buscarPerfil();

    if (perfil == null) {
      return const SinPendientes();
    }

    final pendientes =
        (await _local.obtenerPendientes(perfil.id)).conNombre(perfil.nombre);

    if (pendientes.estaVacio) {
      return const SinPendientes();
    }

    if (!await _conectividad.hayConexion()) {
      return SinConexion(pendientes.cambios);
    }

    try {
      await _remote.enviar(pendientes);
    } catch (error, stack) {
      debugPrint('No se pudo sincronizar el progreso: $error\n$stack');
      return FalloSincronizacion(error, pendientes.cambios);
    }

    return Enviado(await _local.marcarSincronizados(pendientes));
  }

  Future<PerfilEstudiante> _perfilActual() async {
    final perfil = await _buscarPerfil();

    if (perfil == null) {
      throw const SinPerfilException();
    }

    return perfil;
  }

  // Solo se guarda si existe: el perfil puede crearse después de abrir la app.
  Future<PerfilEstudiante?> _buscarPerfil() async {
    return _perfil ??= await _obtenerPerfil();
  }
}
