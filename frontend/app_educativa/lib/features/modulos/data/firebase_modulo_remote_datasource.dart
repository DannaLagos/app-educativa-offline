import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/servidor_exception.dart';
import '../domain/archivo_por_descargar.dart';
import '../domain/manifest_modulo.dart';
import '../domain/modulo.dart';
import 'modulo_remote_datasource.dart';

/// Lee los contenidos desde Firebase Storage:
///
///   contenidos/
///   ├── catalogo.json
///   └── modulos/<id>/manifest.json + archivos del módulo
///
/// Firebase Storage no guarda nada sin conexión: la copia offline la manejan
/// SQLite (catálogo y estado) y [AlmacenamientoModulos] (archivos).
class FirebaseModuloRemoteDataSource implements ModuloRemoteDataSource {
  /// Tamaño máximo aceptado para catalogo.json y manifest.json.
  static const int _maxBytesJson = 1024 * 1024;

  final Reference _raiz;

  FirebaseModuloRemoteDataSource({
    FirebaseStorage? storage,
    String carpetaRaiz = ApiConfig.carpetaFirebase,
  }) : _raiz = (storage ?? FirebaseStorage.instance).ref(carpetaRaiz);

  @override
  Future<List<Modulo>> obtenerCatalogo() async {
    return interpretarCatalogo(
      await _leerJson(_raiz.child('catalogo.json')),
    );
  }

  @override
  Future<ManifestModulo> obtenerManifest(String moduloId) async {
    final json = await _leerJson(
      _carpetaModulo(moduloId).child('manifest.json'),
    );

    return interpretarManifest(moduloId, json);
  }

  @override
  Future<void> descargarArchivo(
    ArchivoPorDescargar archivo, {
    void Function(int bytesRecibidos)? onRecibido,
  }) async {
    final tarea = _carpetaModulo(archivo.moduloId)
        .child(archivo.nombre)
        .writeToFile(File(archivo.rutaDestino));

    final StreamSubscription<TaskSnapshot> suscripcion =
        tarea.snapshotEvents.listen(
      (estado) => onRecibido?.call(estado.bytesTransferred),
      // El error también llega al await de abajo, que es donde se maneja.
      onError: (_) {},
    );

    try {
      await tarea;
    } on FirebaseException catch (error) {
      throw ServidorException(
        'Se interrumpió la descarga de ${archivo.nombre}.',
        error,
      );
    } finally {
      await suscripcion.cancel();
    }
  }

  Reference _carpetaModulo(String moduloId) {
    return _raiz.child('modulos').child(moduloId);
  }

  Future<Map<String, dynamic>> _leerJson(Reference referencia) async {
    final List<int>? bytes;

    try {
      bytes = await referencia.getData(_maxBytesJson);
    } on FirebaseException catch (error) {
      throw ServidorException(
        'No fue posible leer ${referencia.fullPath} (${error.code}).',
        error,
      );
    }

    return interpretarRespuesta(
      () => jsonDecode(utf8.decode(bytes ?? const [])) as Map<String, dynamic>,
      mensajeError: 'El archivo ${referencia.fullPath} no es un JSON válido.',
    );
  }
}
