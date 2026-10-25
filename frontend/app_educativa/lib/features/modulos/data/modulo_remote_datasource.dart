import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/servidor_exception.dart';
import '../domain/archivo_por_descargar.dart';
import '../domain/manifest_modulo.dart';
import '../domain/modulo.dart';

class ModuloRemoteDataSource {
  final Dio _dio;
  final String _baseUrl;

  ModuloRemoteDataSource({
    Dio? dio,
    String baseUrl = ApiConfig.baseUrl,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: ApiConfig.tiempoEspera,
                receiveTimeout: ApiConfig.tiempoEspera,
              ),
            ),
        _baseUrl = baseUrl;

  Future<List<Modulo>> obtenerCatalogo() async {
    final json = await _obtenerJson('$_baseUrl/catalogo.json');

    return _interpretar(
      () => (json['modulos'] as List)
          .map(
            (entrada) => Modulo.desdeCatalogo(
              entrada as Map<String, dynamic>,
            ),
          )
          .toList(),
      mensajeError: 'El catálogo no tiene el formato esperado.',
    );
  }

  Future<ManifestModulo> obtenerManifest(String moduloId) async {
    final json = await _obtenerJson(
      '${_urlModulo(moduloId)}/manifest.json',
    );

    return _interpretar(
      () => ManifestModulo.fromJson(json),
      mensajeError: 'El manifest del módulo $moduloId no es válido.',
    );
  }

  Future<void> descargarArchivo(
    ArchivoPorDescargar archivo, {
    void Function(int bytesRecibidos)? onRecibido,
  }) async {
    try {
      await _dio.download(
        '${_urlModulo(archivo.moduloId)}/'
        '${Uri.encodeComponent(archivo.nombre)}',
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

  String _urlModulo(String moduloId) {
    return '$_baseUrl/modulos/${Uri.encodeComponent(moduloId)}';
  }

  Future<Map<String, dynamic>> _obtenerJson(String url) async {
    final Response<String> respuesta;

    try {
      // GitHub raw sirve los .json como texto plano, así que se decodifica a mano.
      respuesta = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
    } on DioException catch (error) {
      throw ServidorException('No fue posible conectar con $url.', error);
    }

    return _interpretar(
      () => jsonDecode(respuesta.data ?? '') as Map<String, dynamic>,
      mensajeError: 'El servidor respondió algo inválido en $url.',
    );
  }

  T _interpretar<T>(T Function() interpretar, {required String mensajeError}) {
    try {
      return interpretar();
    } on FormatException catch (error) {
      throw ServidorException(mensajeError, error);
    } on TypeError catch (error) {
      throw ServidorException(mensajeError, error);
    }
  }
}
