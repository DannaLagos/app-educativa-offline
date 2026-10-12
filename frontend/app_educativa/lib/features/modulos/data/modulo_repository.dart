import '../../../core/network/conectividad_service.dart';
import '../../../core/network/servidor_exception.dart';
import '../domain/estado_descarga.dart';
import '../domain/modulo.dart';
import '../domain/recurso_local.dart';
import 'almacenamiento_modulos.dart';
import 'modulo_local_datasource.dart';
import 'modulo_remote_datasource.dart';

class ResultadoCatalogo {
  final List<Modulo> modulos;

  /// true cuando no se pudo consultar el servidor y los módulos vienen
  /// de la copia guardada en el dispositivo.
  final bool desdeCache;

  const ResultadoCatalogo({
    required this.modulos,
    required this.desdeCache,
  });
}

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

  /// Intenta actualizar el catálogo desde el servidor; si no hay conexión o
  /// el servidor falla, devuelve el catálogo guardado en SQLite.
  Future<ResultadoCatalogo> obtenerCatalogo() async {
    if (await _conectividad.hayConexion()) {
      try {
        final remotos = await _remote.obtenerCatalogo();
        await _local.guardarCatalogo(remotos);

        return ResultadoCatalogo(
          modulos: await _local.obtenerCatalogo(),
          desdeCache: false,
        );
      } on ServidorException {
        // Se usa la caché local.
      }
    }

    return ResultadoCatalogo(
      modulos: await _local.obtenerCatalogo(),
      desdeCache: true,
    );
  }

  Future<Modulo?> obtenerModulo(String id) => _local.obtenerModulo(id);

  /// Recursos de un módulo descargado. Solo lee archivos del dispositivo:
  /// no consulta la conexión ni el servidor, así que funciona sin internet.
  ///
  /// Si faltan archivos, el módulo pasa a "error" para que se pueda volver
  /// a descargar.
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
}
