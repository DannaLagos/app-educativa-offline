import 'package:flutter/foundation.dart';

import '../../../core/network/conectividad_service.dart';
import '../../perfil/domain/perfil_estudiante.dart';
import '../../progreso/data/progreso_local_datasource.dart';
import '../domain/resultado_sincronizacion.dart';
import 'progreso_remote_datasource.dart';

/// Envía al servidor el progreso pendiente (HU10).
///
/// Regla principal: un registro solo deja de estar pendiente cuando el
/// servidor confirma que lo recibió. Si no hay red o el envío falla, no se
/// borra ni se modifica nada en el teléfono.
class SincronizacionService {
  final ProgresoLocalDataSource _local;
  final ProgresoRemoteDataSource _remote;
  final ConectividadService _conectividad;
  final Future<PerfilEstudiante?> Function() _obtenerPerfil;

  SincronizacionService({
    required ProgresoLocalDataSource local,
    required ProgresoRemoteDataSource remote,
    required ConectividadService conectividad,
    required Future<PerfilEstudiante?> Function() obtenerPerfil,
  })  : _local = local,
        _remote = remote,
        _conectividad = conectividad,
        _obtenerPerfil = obtenerPerfil;

  /// Cuántos avances faltan por enviar (solo lee el teléfono).
  Future<int> contarPendientes() async {
    final perfil = await _obtenerPerfil();

    if (perfil == null) {
      return 0;
    }

    return (await _local.obtenerPendientes(perfil.id)).cambios;
  }

  /// Cuándo se envió el progreso por última vez (guardado en SQLite, así que
  /// se conoce aunque se cierre la app).
  Future<DateTime?> ultimaSincronizacion() async {
    final perfil = await _obtenerPerfil();

    return perfil == null
        ? null
        : _local.obtenerUltimaSincronizacion(perfil.id);
  }

  Future<ResultadoSincronizacion> sincronizar() async {
    final perfil = await _obtenerPerfil();

    if (perfil == null) {
      return const SinPendientes();
    }

    final pendientes =
        (await _local.obtenerPendientes(perfil.id)).conNombre(perfil.nombre);

    if (pendientes.estaVacio) {
      return const SinPendientes();
    }

    // Criterio 2: sin red los datos se conservan hasta poder enviarlos.
    if (!await _conectividad.hayConexion()) {
      return SinConexion(pendientes.cambios);
    }

    try {
      await _remote.enviar(pendientes);
    } catch (error, stack) {
      // Criterio 3: si falla, no se toca nada; todo sigue pendiente.
      debugPrint('No se pudo sincronizar el progreso: $error\n$stack');
      return FalloSincronizacion(error, pendientes.cambios);
    }

    return Enviado(await _local.marcarSincronizados(pendientes));
  }
}
