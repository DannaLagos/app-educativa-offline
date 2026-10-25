import 'dart:developer';

import '../../../core/network/conectividad_service.dart';
import '../../../core/network/servidor_exception.dart';
import '../domain/contenido_incompleto_exception.dart';
import '../domain/estado_descarga.dart';
import '../domain/modulo.dart';
import '../domain/recurso_local.dart';
import '../domain/resultado_catalogo.dart';
import 'almacenamiento_modulos.dart';
import 'modulo_local_datasource.dart';
import 'modulo_remote_datasource.dart';

class ModuloRepository {
  final ModuloRemoteDataSource _remote;
  final ModuloLocalDataSource _local;
  final ConectividadService _conectividad;
  final AlmacenamientoModulos _almacenamiento;

  ModuloRepository({
    required ModuloRemoteDataSource remote,
    required ModuloLocalDataSource local,
    required ConectividadService conectividad,
    required AlmacenamientoModulos almacenamiento,
  })  : _remote = remote,
        _local = local,
        _conectividad = conectividad,
        _almacenamiento = almacenamiento;

  Future<ResultadoCatalogo> obtenerCatalogo() async {
    final seActualizoDesdeServidor = await _actualizarCatalogoDesdeServidor();

    return ResultadoCatalogo(
      modulos: await _local.obtenerCatalogo(),
      vieneDeCache: !seActualizoDesdeServidor,
    );
  }

  Future<Modulo?> obtenerModulo(String id) => _local.obtenerModulo(id);

  Future<List<Modulo>> obtenerDescargados() {
    return _local.obtenerPorEstado(EstadoDescarga.descargado);
  }

  // Primero la base: si falla el borrado, la carpeta huérfana se limpia al iniciar.
  Future<void> eliminarDescarga(Modulo modulo) async {
    await _local.actualizarEstadoDescarga(
      modulo.id,
      EstadoDescarga.noDescargado,
    );
    await _almacenamiento.eliminar(modulo.id);
  }

  Future<List<RecursoLocal>> obtenerRecursosLocales(Modulo modulo) async {
    final rutaLocal = modulo.rutaLocal;

    if (!modulo.estaDescargado || rutaLocal == null) {
      throw ContenidoIncompletoException(
        'El módulo ${modulo.id} no está descargado.',
      );
    }

    try {
      return await _almacenamiento.leerRecursos(rutaLocal);
    } on ContenidoIncompletoException {
      await _local.actualizarEstadoDescarga(modulo.id, EstadoDescarga.error);
      rethrow;
    }
  }

  Future<bool> _actualizarCatalogoDesdeServidor() async {
    if (!await _conectividad.hayConexion()) {
      return false;
    }

    try {
      final modulosRemotos = await _remote.obtenerCatalogo();
      await _local.guardarCatalogo(modulosRemotos);
      return true;
    } on ServidorException catch (error) {
      log(
        'Se usa el catálogo guardado: $error',
        name: 'ModuloRepository',
      );
      return false;
    }
  }
}
