import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/manifest_modulo.dart';
import '../domain/recurso_local.dart';

/// Maneja las carpetas de los módulos en el almacenamiento privado de la app:
///
///   modulos/.tmp_<id>/  descarga en curso (nunca se lee desde la interfaz)
///   modulos/<id>/       módulo completo y verificado
class AlmacenamientoModulos {
  static const String _prefijoTemporal = '.tmp_';

  final Future<Directory> Function() _directorioBase;

  AlmacenamientoModulos({
    Future<Directory> Function()? directorioBase,
  }) : _directorioBase = directorioBase ?? getApplicationSupportDirectory;

  Future<Directory> _carpetaModulos() async {
    final base = await _directorioBase();
    final carpeta = Directory(p.join(base.path, 'modulos'));
    await carpeta.create(recursive: true);

    return carpeta;
  }

  Future<Directory> carpetaFinal(String moduloId) async {
    return Directory(p.join((await _carpetaModulos()).path, moduloId));
  }

  /// Crea una carpeta temporal vacía para descargar el módulo.
  Future<Directory> crearCarpetaTemporal(String moduloId) async {
    final temporal = Directory(
      p.join((await _carpetaModulos()).path, '$_prefijoTemporal$moduloId'),
    );

    if (await temporal.exists()) {
      await temporal.delete(recursive: true);
    }

    return temporal.create(recursive: true);
  }

  /// Reemplaza la carpeta final por la temporal con un renombrado, que en el
  /// mismo sistema de archivos es atómico: o queda el módulo completo o no
  /// queda nada.
  Future<Directory> confirmar(String moduloId) async {
    final carpetaModulos = await _carpetaModulos();
    final temporal = Directory(
      p.join(carpetaModulos.path, '$_prefijoTemporal$moduloId'),
    );
    final destino = Directory(p.join(carpetaModulos.path, moduloId));

    if (await destino.exists()) {
      await destino.delete(recursive: true);
    }

    return temporal.rename(destino.path);
  }

  /// Lee los recursos de un módulo descargado usando solo archivos locales.
  Future<List<RecursoLocal>> leerRecursos(String rutaLocal) async {
    final manifestArchivo = File(p.join(rutaLocal, 'manifest.json'));

    if (!await manifestArchivo.exists()) {
      throw ContenidoIncompletoException('Falta ${manifestArchivo.path}');
    }

    final ManifestModulo manifest;

    try {
      manifest = ManifestModulo.fromJson(
        jsonDecode(await manifestArchivo.readAsString())
            as Map<String, dynamic>,
      );
    } on FormatException catch (error) {
      throw ContenidoIncompletoException('Manifest dañado: $error');
    } on TypeError catch (error) {
      throw ContenidoIncompletoException('Manifest dañado: $error');
    }

    final recursos = <RecursoLocal>[];

    for (final recurso in manifest.recursos) {
      final archivo = File(p.join(rutaLocal, recurso.archivo));

      if (!await archivo.exists()) {
        throw ContenidoIncompletoException('Falta ${archivo.path}');
      }

      recursos.add(
        RecursoLocal(
          titulo: recurso.titulo,
          tipo: recurso.tipo,
          ruta: archivo.path,
        ),
      );
    }

    return recursos;
  }

  Future<void> eliminar(String moduloId) async {
    final carpeta = await carpetaFinal(moduloId);

    if (await carpeta.exists()) {
      await carpeta.delete(recursive: true);
    }
  }

  Future<void> eliminarTemporal(String moduloId) async {
    final temporal = Directory(
      p.join((await _carpetaModulos()).path, '$_prefijoTemporal$moduloId'),
    );

    if (await temporal.exists()) {
      await temporal.delete(recursive: true);
    }
  }

  /// Borra descargas que quedaron a medias (por ejemplo, si se cerró la app)
  /// y carpetas de módulos que la base de datos no reconoce como descargados.
  Future<void> limpiar({required Set<String> idsDescargados}) async {
    final carpetaModulos = await _carpetaModulos();

    await for (final entrada in carpetaModulos.list()) {
      if (entrada is! Directory) {
        continue;
      }

      final nombre = p.basename(entrada.path);

      if (nombre.startsWith(_prefijoTemporal) ||
          !idsDescargados.contains(nombre)) {
        await entrada.delete(recursive: true);
      }
    }
  }
}
