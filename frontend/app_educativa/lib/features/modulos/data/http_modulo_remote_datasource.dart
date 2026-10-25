import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/servidor_exception.dart';
import '../domain/archivo_por_descargar.dart';
import '../domain/manifest_modulo.dart';
import '../domain/modulo.dart';
import 'modulo_remote_datasource.dart';

/// Lee los contenidos desde un servidor HTTP con la estructura
/// `catalogo.json` + `modulos/<id>/...`. Se usa para pruebas con un servidor
/// local (`--dart-define=FUENTE_CONTENIDOS=http`).
class HttpModuloRemoteDataSource implements ModuloRemoteDataSource {
  final Dio _dio;
  final String _baseUrl;

  HttpModuloRemoteDataSource({
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

  @override
  Future<List<Modulo>> obtenerCatalogo() async {
    return interpretarCatalogo(await _obtenerJson('$_baseUrl/catalogo.json'));
  }

  @override
  Future<ManifestModulo> obtenerManifest(String moduloId) async {
    final json = await _obtenerJson('${_urlModulo(moduloId)}/manifest.json');

    return interpretarManifest(moduloId, json);
  }

  @override
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
      // Algunos servidores sirven los .json como texto plano, así que se
      // decodifica a mano.
      respuesta = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
    } on DioException catch (error) {
      throw ServidorException('No fue posible conectar con $url.', error);
    }

    return interpretarRespuesta(
      () => jsonDecode(respuesta.data ?? '') as Map<String, dynamic>,
      mensajeError: 'El servidor respondió algo inválido en $url.',
    );
  }
}
