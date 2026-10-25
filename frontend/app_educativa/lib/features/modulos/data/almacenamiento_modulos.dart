import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/contenido_incompleto_exception.dart';
import '../domain/manifest_modulo.dart';
import '../domain/recurso_local.dart';

// Estructura: modulos/.tmp_<id>/ (descarga en curso) y modulos/<id>/ (módulo verificado).
class AlmacenamientoModulos {
  static const String _prefijoTemporal = '.tmp_';
  static const String _nombreCarpetaModulos = 'modulos';
  static const String _nombreManifest = 'manifest.json';

  final Future<Directory> Function() _obtenerDirectorioBase;

  AlmacenamientoModulos({
    Future<Directory> Function()? directorioBase,
  }) : _obtenerDirectorioBase =
            directorioBase ?? getApplicationSupportDirectory;

  Future<Directory> carpetaFinal(String moduloId) async {
    return Directory(p.join((await _carpetaModulos()).path, moduloId));
  }

  Future<Directory> crearCarpetaTemporal(String moduloId) async {
    final temporal = await _carpetaTemporal(moduloId);
    await _eliminarSiExiste(temporal);

    return temporal.create(recursive: true);
  }

  // El renombrado es atómico en el mismo sistema de archivos: queda todo o nada.
  Future<Directory> confirmar(String moduloId) async {
    final temporal = await _carpetaTemporal(moduloId);
    final destino = await carpetaFinal(moduloId);
    await _eliminarSiExiste(destino);

    return temporal.rename(destino.path);
  }

  Future<List<RecursoLocal>> leerRecursos(String rutaLocal) async {
    final manifest = await _leerManifest(rutaLocal);

    return [
      for (final recurso in manifest.recursos)
        await _ubicarRecurso(rutaLocal, recurso),
    ];
  }

  Future<void> eliminar(String moduloId) async {
    await _eliminarSiExiste(await carpetaFinal(moduloId));
  }

  Future<void> eliminarTemporal(String moduloId) async {
    await _eliminarSiExiste(await _carpetaTemporal(moduloId));
  }

  Future<void> limpiar({required Set<String> idsDescargados}) async {
    final carpetaModulos = await _carpetaModulos();

    await for (final entrada in carpetaModulos.list()) {
      if (entrada is Directory &&
          _esCarpetaSobrante(entrada, idsDescargados)) {
        await entrada.delete(recursive: true);
      }
    }
  }

  bool _esCarpetaSobrante(Directory carpeta, Set<String> idsDescargados) {
    final nombre = p.basename(carpeta.path);

    return nombre.startsWith(_prefijoTemporal) ||
        !idsDescargados.contains(nombre);
  }

  Future<ManifestModulo> _leerManifest(String rutaLocal) async {
    final archivoManifest = File(p.join(rutaLocal, _nombreManifest));

    if (!await archivoManifest.exists()) {
      throw ContenidoIncompletoException('Falta ${archivoManifest.path}');
    }

    final contenido = await archivoManifest.readAsString();

    try {
      return ManifestModulo.fromJson(
        jsonDecode(contenido) as Map<String, dynamic>,
      );
    } on FormatException catch (error) {
      throw ContenidoIncompletoException('Manifest dañado: $error');
    } on TypeError catch (error) {
      throw ContenidoIncompletoException('Manifest dañado: $error');
    }
  }

  Future<RecursoLocal> _ubicarRecurso(
    String rutaLocal,
    RecursoModulo recurso,
  ) async {
    final archivo = File(p.join(rutaLocal, recurso.archivo));

    if (!await archivo.exists()) {
      throw ContenidoIncompletoException('Falta ${archivo.path}');
    }

    return RecursoLocal(
      titulo: recurso.titulo,
      tipo: recurso.tipo,
      ruta: archivo.path,
    );
  }

  Future<Directory> _carpetaModulos() async {
    final base = await _obtenerDirectorioBase();
    final carpeta = Directory(p.join(base.path, _nombreCarpetaModulos));
    await carpeta.create(recursive: true);

    return carpeta;
  }

  Future<Directory> _carpetaTemporal(String moduloId) async {
    final carpetaModulos = await _carpetaModulos();

    return Directory(
      p.join(carpetaModulos.path, '$_prefijoTemporal$moduloId'),
    );
  }

  Future<void> _eliminarSiExiste(Directory carpeta) async {
    if (await carpeta.exists()) {
      await carpeta.delete(recursive: true);
    }
  }
}
