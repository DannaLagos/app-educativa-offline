import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/servidor_exception.dart';
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

    try {
      return (json['modulos'] as List)
          .map(
            (entrada) => Modulo.desdeCatalogo(
              entrada as Map<String, dynamic>,
            ),
          )
          .toList();
    } on TypeError catch (error) {
      throw ServidorException('El catálogo no tiene el formato esperado.', error);
    }
  }

  Future<Map<String, dynamic>> _obtenerJson(String url) async {
    try {
      // GitHub raw sirve los .json como texto plano, así que se decodifica
      // a mano en lugar de confiar en el Content-Type.
      final respuesta = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );

      return jsonDecode(respuesta.data ?? '') as Map<String, dynamic>;
    } on DioException catch (error) {
      throw ServidorException('No fue posible conectar con el servidor.', error);
    } on FormatException catch (error) {
      throw ServidorException('El servidor respondió algo inválido.', error);
    } on TypeError catch (error) {
      throw ServidorException('El servidor respondió algo inválido.', error);
    }
  }
}
