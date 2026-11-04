import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
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
/// La lista de módulos se lee primero de la colección `catalogo` de
/// Firestore, que es la que edita el superadministrador (HU13).
///
/// Cada archivo se descarga por su URL: Firebase Storage la entrega y la app
/// la descarga por HTTP. Antes de leer se inicia la sesión anónima, porque
/// las reglas de Storage solo dejan leer a la app (`request.auth != null`).
/// La copia offline la manejan SQLite (catálogo y estado) y
/// [AlmacenamientoModulos] (archivos).
class FirebaseModuloRemoteDataSource implements ModuloRemoteDataSource {
  /// Tamaño máximo aceptado para catalogo.json y manifest.json.
  static const int _maxBytesJson = 1024 * 1024;

  final Reference _raiz;
  final Dio _dio;
  final Future<Object?> Function()? _iniciarSesion;

  /// Sin Firestore, el catálogo sale solo de catalogo.json.
  final FirebaseFirestore? _firestore;

  FirebaseModuloRemoteDataSource({
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
    Dio? dio,
    Future<Object?> Function()? iniciarSesion,
    String carpetaRaiz = ApiConfig.carpetaFirebase,
  })  : _raiz = (storage ?? FirebaseStorage.instance).ref(carpetaRaiz),
        _firestore = firestore,
        _iniciarSesion = iniciarSesion,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: ApiConfig.tiempoEspera,
                receiveTimeout: ApiConfig.tiempoEspera,
              ),
            );

  @override
  Future<List<Modulo>> obtenerCatalogo() async {
    final desdeFirestore = await _leerCatalogoFirestore();

    if (desdeFirestore != null) {
      return desdeFirestore;
    }

    return interpretarCatalogo(
      await _leerJson(_raiz.child('catalogo.json')),
    );
  }

  /// HU13: los módulos que edita el superadministrador están en Firestore.
  /// Trae también los deshabilitados: SQLite los guarda y solo muestra los
  /// habilitados (criterio 4).
  ///
  /// Devuelve null para usar catalogo.json mientras la colección no exista
  /// (vacía o sin reglas publicadas). Otro error se lanza, para que el
  /// repositorio use la copia guardada y no un catalogo.json viejo que
  /// volvería a mostrar módulos deshabilitados.
  Future<List<Modulo>?> _leerCatalogoFirestore() async {
    final firestore = _firestore;

    if (firestore == null) {
      return null;
    }

    final QuerySnapshot<Map<String, dynamic>> consulta;

    try {
      await _iniciarSesion?.call();
      consulta = await firestore
          .collection(ApiConfig.coleccionCatalogo)
          .get()
          .timeout(ApiConfig.tiempoEspera);
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return null;
      }

      throw ServidorException('No fue posible leer el catálogo.', error);
    } on TimeoutException catch (error) {
      throw ServidorException('El catálogo tardó demasiado.', error);
    }

    if (consulta.docs.isEmpty) {
      return null;
    }

    return interpretarRespuesta(
      () => [
        for (final documento in consulta.docs)
          Modulo.desdeCatalogo({...documento.data(), 'id': documento.id}),
      ],
      mensajeError: 'El catálogo de Firestore no tiene el formato esperado.',
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
    final url = await obtenerUrl(archivo);

    try {
      await _dio.download(
        url,
        archivo.rutaDestino,
        onReceiveProgress: (bytesRecibidos, _) =>
            onRecibido?.call(bytesRecibidos),
      );
    } on DioException catch (error) {
      throw ServidorException(
        'Se interrumpió la descarga de ${archivo.nombre}.',
        error,
      );
    }
  }

  /// URL de descarga del archivo en Firebase Storage.
  Future<String> obtenerUrl(ArchivoPorDescargar archivo) async {
    final referencia = _carpetaModulo(archivo.moduloId).child(archivo.nombre);

    try {
      await _iniciarSesion?.call();
      return await referencia.getDownloadURL();
    } on FirebaseException catch (error) {
      throw ServidorException(
        'No se encontró la URL de ${referencia.fullPath} (${error.code}).',
        error,
      );
    }
  }

  Reference _carpetaModulo(String moduloId) {
    return _raiz.child('modulos').child(moduloId);
  }

  Future<Map<String, dynamic>> _leerJson(Reference referencia) async {
    final List<int>? bytes;

    try {
      await _iniciarSesion?.call();
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
