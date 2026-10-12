import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../../core/network/conectividad_service.dart';
import '../../../core/network/servidor_exception.dart';
import '../domain/estado_descarga.dart';
import '../domain/manifest_modulo.dart';
import '../domain/modulo.dart';
import 'almacenamiento_modulos.dart';
import 'modulo_local_datasource.dart';
import 'modulo_remote_datasource.dart';

enum MotivoFalloDescarga {
  sinConexion(
    'No hay internet. Conéctate a una red y vuelve a intentarlo.',
  ),
  conexionInterrumpida(
    'Se perdió la conexión durante la descarga. Vuelve a intentarlo.',
  ),
  archivoDanado(
    'Un archivo llegó dañado. Vuelve a intentarlo.',
  ),
  sinEspacio(
    'No se pudo guardar el módulo. Revisa que haya espacio libre.',
  );

  /// Mensaje para mostrar al estudiante.
  final String mensaje;

  const MotivoFalloDescarga(this.mensaje);
}

class DescargaException implements Exception {
  final MotivoFalloDescarga motivo;
  final Object? causa;

  const DescargaException(this.motivo, [this.causa]);

  String get mensaje => motivo.mensaje;

  @override
  String toString() => 'DescargaException: ${motivo.name} ($causa)';
}

/// Descarga un módulo de forma atómica: todo va a una carpeta temporal, se
/// verifica cada archivo y solo al final se mueve a su carpeta definitiva y
/// se marca como "descargado".
///
/// También sirve para actualizar un módulo ya descargado: la versión anterior
/// sigue en su carpeta hasta que la nueva está completa, y si la
/// actualización falla se conserva la anterior.
class DescargaService {
  final ModuloRemoteDataSource _remote;
  final ModuloLocalDataSource _local;
  final ConectividadService _conectividad;
  final AlmacenamientoModulos _almacenamiento;
  final DateTime Function() _ahora;

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
        _ahora = ahora ?? DateTime.now;

  /// [onProgreso] recibe valores entre 0 y 1.
  Future<void> descargar(
    Modulo modulo, {
    void Function(double progreso)? onProgreso,
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
      final manifest = await _remote.obtenerManifest(modulo.id);
      final temporal = await _almacenamiento.crearCarpetaTemporal(modulo.id);

      await _descargarRecursos(modulo.id, manifest, temporal, onProgreso);

      await File(p.join(temporal.path, 'manifest.json')).writeAsString(
        jsonEncode(manifest.toJson()),
      );

      final carpeta = await _almacenamiento.confirmar(modulo.id);

      await _local.actualizarEstadoDescarga(
        modulo.id,
        EstadoDescarga.descargado,
        rutaLocal: carpeta.path,
        fechaDescarga: _ahora(),
        versionDescargada: manifest.version,
      );
      onProgreso?.call(1);
    } catch (error) {
      await _deshacer(modulo);

      if (error is DescargaException) {
        rethrow;
      }
      if (error is ServidorException) {
        throw DescargaException(
          MotivoFalloDescarga.conexionInterrumpida,
          error,
        );
      }
      if (error is FileSystemException) {
        throw DescargaException(MotivoFalloDescarga.sinEspacio, error);
      }
      rethrow;
    }
  }

  Future<void> _descargarRecursos(
    String moduloId,
    ManifestModulo manifest,
    Directory temporal,
    void Function(double progreso)? onProgreso,
  ) async {
    final total = manifest.tamanoTotal;
    var completados = 0;

    for (final recurso in manifest.recursos) {
      final destino = File(p.join(temporal.path, recurso.archivo));

      await _remote.descargarArchivo(
        moduloId: moduloId,
        archivo: recurso.archivo,
        destino: destino.path,
        onRecibido: (recibidos) {
          if (total > 0) {
            final progreso = (completados + recibidos) / total;
            onProgreso?.call(progreso.clamp(0, 0.99).toDouble());
          }
        },
      );

      await _verificar(destino, recurso);
      completados += recurso.tamano;
    }
  }

  Future<void> _verificar(File archivo, RecursoModulo recurso) async {
    final tamano = await archivo.length();
    final resumen = await sha256.bind(archivo.openRead()).first;

    if (tamano != recurso.tamano || resumen.toString() != recurso.sha256) {
      throw DescargaException(
        MotivoFalloDescarga.archivoDanado,
        'Verificación fallida para ${recurso.archivo}',
      );
    }
  }

  Future<void> _deshacer(Modulo modulo) async {
    try {
      await _almacenamiento.eliminarTemporal(modulo.id);
    } on FileSystemException {
      // Se limpia al próximo inicio con limpiarIncompletas().
    }

    if (modulo.estaDescargado) {
      // Falló una actualización: la versión anterior sigue intacta.
      await _local.actualizarEstadoDescarga(
        modulo.id,
        EstadoDescarga.descargado,
        rutaLocal: modulo.rutaLocal,
        fechaDescarga: modulo.fechaDescarga,
        versionDescargada: modulo.versionDescargada,
      );
    } else {
      await _local.actualizarEstadoDescarga(modulo.id, EstadoDescarga.error);
    }
  }

  /// Se llama al abrir la app: borra descargas a medias y carpetas que no
  /// corresponden a un módulo descargado.
  Future<void> limpiarIncompletas() async {
    await _local.marcarDescargasInterrumpidas();

    final descargados = await _local.obtenerPorEstado(
      EstadoDescarga.descargado,
    );

    await _almacenamiento.limpiar(
      idsDescargados: descargados.map((modulo) => modulo.id).toSet(),
    );
  }
}
