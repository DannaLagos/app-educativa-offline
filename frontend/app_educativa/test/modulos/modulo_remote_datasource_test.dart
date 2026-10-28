import 'package:app_educativa/core/network/servidor_exception.dart';
import 'package:app_educativa/features/modulos/data/http_modulo_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late HttpModuloRemoteDataSource remote;

  setUpAll(() => registerFallbackValue(Options()));

  setUp(() {
    dio = MockDio();
    remote = HttpModuloRemoteDataSource(dio: dio, baseUrl: 'https://servidor');
  });

  void responder(String cuerpo) {
    when(
      () => dio.get<String>(
        'https://servidor/catalogo.json',
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: cuerpo,
        requestOptions: RequestOptions(),
      ),
    );
  }

  test('lee el catálogo (servido como texto plano)', () async {
    responder('''
      {"modulos": [{
        "id": "cs-grado-1", "nombre": "Ciencias Sociales",
        "area": "Ciencias Sociales", "grado": 1, "descripcion": "D",
        "version": 2, "habilitado": true, "contenidos": ["Mi familia"]
      }]}
    ''');

    final modulos = await remote.obtenerCatalogo();

    expect(modulos.single.id, 'cs-grado-1');
    expect(modulos.single.version, 2);
    expect(modulos.single.contenidos, ['Mi familia']);
  });

  test('un JSON inválido se convierte en ServidorException', () async {
    responder('<html>404</html>');

    expect(remote.obtenerCatalogo(), throwsA(isA<ServidorException>()));
  });

  test('un catálogo con campos faltantes se convierte en ServidorException',
      () async {
    responder('{"modulos": [{"id": "x"}]}');

    expect(remote.obtenerCatalogo(), throwsA(isA<ServidorException>()));
  });

  test('un error de red se convierte en ServidorException', () async {
    when(
      () => dio.get<String>(any(), options: any(named: 'options')),
    ).thenThrow(
      DioException.connectionError(
        requestOptions: RequestOptions(),
        reason: 'sin red',
      ),
    );

    expect(remote.obtenerCatalogo(), throwsA(isA<ServidorException>()));
  });
}
