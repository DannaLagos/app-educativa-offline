import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../../core/network/conectividad_service.dart';
import '../../../core/network/servidor_exception.dart';
import '../domain/archivo_por_descargar.dart';
import '../domain/descarga_exception.dart';
import '../domain/estado_descarga.dart';
import '../domain/manifest_modulo.dart';
import '../domain/modulo.dart';
import 'almacenamiento_modulos.dart';
import 'modulo_local_datasource.dart';
import 'modulo_remote_datasource.dart';

typedef AlRecibirProgreso = void Function(double progreso);

// Descarga en una carpeta temporal y solo al final reemplaza la versión anterior.
class DescargaService {
  static const double _progresoMaximoAntesDeConfirmar = 0.99;
  static const String _nombreManifest = 'manifest.json';

  final ModuloRemoteDataSource _remote;
  final ModuloLocalDataSource _local;
  final ConectividadService _conectividad;
  final AlmacenamientoModulos _almacenamiento;
  final DateTime Function() _obtenerAhora;

  DescargaService({
    required ModuloRemoteDataSource remote,
    required ModuloLocalDataSource local,
    required ConectividadService conectividad,
    required AlmacenamientoModulos almacenamiento,
    DateTime Function()? ahora,
  })  : _remote = remote,
        _local = local,
        _conectividad = conectividad,
        _almacenamiento = almacenamiento,
        _obtenerAhora = ahora ?? DateTime.now;

  Future<void> descargar(
    Modulo modulo, {
    AlRecibirProgreso? onProgreso,
  }) async {
    if (!await _conectividad.hayConexion()) {
      throw const DescargaException(MotivoFalloDescarga.sinConexion);
    }

    await _local.actualizarEstadoDescarga(
      modulo.id,
      EstadoDescarga.descargando,
    );
    onProgreso?.call(0);

    try {
      await _descargarYConfirmar(modulo.id, onProgreso);
      onProgreso?.call(1);
    } catch (error, stack) {
      await _deshacer(modulo);
      Error.throwWithStackTrace(_traducirError(error), stack);
    }
  }

  Future<void> limpiarIncompletas() async {
    await _local.marcarDescargasInterrumpidas();

    final descargados = await _local.obtenerPorEstado(
      EstadoDescarga.descargado,
    );

    await _almacenamiento.limpiar(
      idsDescargados: descargados.map((modulo) => modulo.id).toSet(),
    );
  }

  Future<void> _descargarYConfirmar(
    String moduloId,
    AlRecibirProgreso? onProgreso,
  ) async {
    final manifest = await _remote.obtenerManifest(moduloId);
    final descarga = _DescargaEnCurso(
      moduloId: moduloId,
      carpetaTemporal: await _almacenamiento.crearCarpetaTemporal(moduloId),
      onProgreso: onProgreso,
    );

    await _descargarRecursos(descarga, manifest);
    await _guardarManifest(manifest, descarga.carpetaTemporal);

    final carpeta = await _almacenamiento.confirmar(moduloId);

    await _local.actualizarEstadoDescarga(
      moduloId,
      EstadoDescarga.descargado,
      rutaLocal: carpeta.path,
      fechaDescarga: _obtenerAhora(),
      versionDescargada: manifest.version,
    );
  }

  Future<void> _descargarRecursos(
    _DescargaEnCurso descarga,
    ManifestModulo manifest,
  ) async {
    final bytesTotales = manifest.tamanoTotal;
    var bytesCompletados = 0;

    for (final recurso in manifest.recursos) {
      final destino = File(
        p.join(descarga.carpetaTemporal.path, recurso.archivo),
      );

      await _remote.descargarArchivo(
        ArchivoPorDescargar(
          moduloId: descarga.moduloId,
          nombre: recurso.archivo,
          rutaDestino: destino.path,
        ),
        onRecibido: (bytesRecibidos) => _informarProgreso(
          bytesCompletados + bytesRecibidos,
          bytesTotales,
          descarga.onProgreso,
        ),
      );

      await _verificarIntegridad(destino, recurso);
      bytesCompletados += recurso.tamano;
    }
  }

  void _informarProgreso(
    int bytesRecibidos,
    int bytesTotales,
    AlRecibirProgreso? onProgreso,
  ) {
    if (bytesTotales <= 0) {
      return;
    }

    final progreso = bytesRecibidos / bytesTotales;
    onProgreso?.call(
      progreso.clamp(0, _progresoMaximoAntesDeConfirmar).toDouble(),
    );
  }

  Future<void> _verificarIntegridad(File archivo, RecursoModulo recurso) async {
    final tamano = await archivo.length();
    final resumen = await sha256.bind(archivo.openRead()).first;

    if (tamano != recurso.tamano || resumen.toString() != recurso.sha256) {
      throw DescargaException(
        MotivoFalloDescarga.archivoDanado,
        'Verificación fallida para ${recurso.archivo}',
      );
    }
  }

  Future<void> _guardarManifest(
    ManifestModulo manifest,
    Directory carpeta,
  ) async {
    await File(p.join(carpeta.path, _nombreManifest)).writeAsString(
      jsonEncode(manifest.toJson()),
    );
  }

  Object _traducirError(Object error) {
    if (error is ServidorException) {
      return DescargaException(MotivoFalloDescarga.conexionInterrumpida, error);
    }
    if (error is FileSystemException) {
      return DescargaException(MotivoFalloDescarga.sinEspacio, error);
    }

    return error;
  }

  Future<void> _deshacer(Modulo modulo) async {
    await _eliminarTemporal(modulo.id);

    if (modulo.estaDescargado) {
      await _restaurarVersionAnterior(modulo);
      return;
    }

    await _local.actualizarEstadoDescarga(modulo.id, EstadoDescarga.error);
  }

  Future<void> _eliminarTemporal(String moduloId) async {
    try {
      await _almacenamiento.eliminarTemporal(moduloId);
    } on FileSystemException catch (error) {
      log(
        'No se pudo borrar la carpeta temporal de $moduloId; '
        'se limpiará al próximo inicio: $error',
        name: 'DescargaService',
      );
    }
  }

  Future<void> _restaurarVersionAnterior(Modulo modulo) async {
    await _local.actualizarEstadoDescarga(
      modulo.id,
      EstadoDescarga.descargado,
      rutaLocal: modulo.rutaLocal,
      fechaDescarga: modulo.fechaDescarga,
      versionDescargada: modulo.versionDescargada,
    );
  }
}

class _DescargaEnCurso {
  final String moduloId;
  final Directory carpetaTemporal;
  final AlRecibirProgreso? onProgreso;

  const _DescargaEnCurso({
    required this.moduloId,
    required this.carpetaTemporal,
    required this.onProgreso,
  });
}
