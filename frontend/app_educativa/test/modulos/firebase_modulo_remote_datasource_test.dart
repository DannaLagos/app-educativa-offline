import 'dart:convert';
import 'dart:typed_data';

import 'package:app_educativa/core/network/servidor_exception.dart';
import 'package:app_educativa/features/modulos/data/firebase_modulo_remote_datasource.dart';
import 'package:app_educativa/features/modulos/domain/archivo_por_descargar.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements FirebaseStorage {}

class MockReference extends Mock implements Reference {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockStorage storage;
  late MockReference raiz;
  late MockReference catalogo;
  late MockReference modulos;
  late MockReference carpetaModulo;
  late MockReference manifest;
  late MockReference pdf;
  late MockDio dio;
  late FirebaseModuloRemoteDataSource remote;

  MockReference referencia(String ruta) {
    final ref = MockReference();
    when(() => ref.fullPath).thenReturn(ruta);
    return ref;
  }

  setUp(() {
    storage = MockStorage();
    raiz = referencia('contenidos');
    catalogo = referencia('contenidos/catalogo.json');
    modulos = referencia('contenidos/modulos');
    carpetaModulo = referencia('contenidos/modulos/cs-grado-1');
    manifest = referencia('contenidos/modulos/cs-grado-1/manifest.json');
    pdf = referencia('contenidos/modulos/cs-grado-1/fichas.pdf');
    dio = MockDio();

    when(() => storage.ref('contenidos')).thenReturn(raiz);
    when(() => raiz.child('catalogo.json')).thenReturn(catalogo);
    when(() => raiz.child('modulos')).thenReturn(modulos);
    when(() => modulos.child('cs-grado-1')).thenReturn(carpetaModulo);
    when(() => carpetaModulo.child('manifest.json')).thenReturn(manifest);
    when(() => carpetaModulo.child('fichas.pdf')).thenReturn(pdf);

    remote = FirebaseModuloRemoteDataSource(storage: storage, dio: dio);
  });

  void responder(MockReference ref, String cuerpo) {
    when(() => ref.getData(any())).thenAnswer(
      (_) async => Uint8List.fromList(utf8.encode(cuerpo)),
    );
  }

  test('lee el catálogo desde contenidos/catalogo.json', () async {
    responder(catalogo, '''
      {"modulos": [{
        "id": "cs-grado-1", "nombre": "Ciencias Sociales",
        "area": "Ciencias Sociales", "grado": 1, "descripcion": "D",
        "version": 2, "habilitado": true, "contenidos": ["Mi familia"]
      }]}
    ''');

    final resultado = await remote.obtenerCatalogo();

    expect(resultado.single.id, 'cs-grado-1');
    expect(resultado.single.version, 2);
    expect(resultado.single.contenidos, ['Mi familia']);
  });

  test('lee el manifest desde contenidos/modulos/<id>/manifest.json',
      () async {
    responder(manifest, '''
      {"id": "cs-grado-1", "version": 2, "recursos": [{
        "archivo": "fichas.pdf", "titulo": "Fichas", "tipo": "pdf",
        "tamano": 10, "sha256": "abc"
      }]}
    ''');

    final resultado = await remote.obtenerManifest('cs-grado-1');

    expect(resultado.version, 2);
    expect(resultado.recursos.single.archivo, 'fichas.pdf');
  });

  test('un JSON inválido se convierte en ServidorException', () async {
    responder(catalogo, '<html>404</html>');

    expect(remote.obtenerCatalogo(), throwsA(isA<ServidorException>()));
  });

  test('inicia la sesión antes de leer, porque Storage exige estar autenticado',
      () async {
    var sesiones = 0;
    remote = FirebaseModuloRemoteDataSource(
      storage: storage,
      dio: dio,
      iniciarSesion: () async => sesiones++,
    );
    responder(catalogo, '{"modulos": []}');

    await remote.obtenerCatalogo();

    expect(sesiones, 1);
  });

  test('si no se puede iniciar sesión, avisa con ServidorException', () async {
    remote = FirebaseModuloRemoteDataSource(
      storage: storage,
      dio: dio,
      iniciarSesion: () async => throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'network-request-failed',
      ),
    );

    expect(remote.obtenerCatalogo(), throwsA(isA<ServidorException>()));
    verifyNever(() => catalogo.getData(any()));
  });

  test('un error de Firebase se convierte en ServidorException', () async {
    when(() => catalogo.getData(any())).thenThrow(
      FirebaseException(plugin: 'firebase_storage', code: 'object-not-found'),
    );

    expect(remote.obtenerCatalogo(), throwsA(isA<ServidorException>()));
  });

  group('descarga por URL', () {
    const archivo = ArchivoPorDescargar(
      moduloId: 'cs-grado-1',
      nombre: 'fichas.pdf',
      rutaDestino: '/tmp/fichas.pdf',
    );
    const url = 'https://firebasestorage.googleapis.com/v0/b/app/o/fichas.pdf';

    void descargaResponde() {
      when(
        () => dio.download(
          any(),
          any(),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(requestOptions: RequestOptions()),
      );
    }

    test('pide la URL a Firebase Storage y descarga el archivo con ella',
        () async {
      when(() => pdf.getDownloadURL()).thenAnswer((_) async => url);
      descargaResponde();

      await remote.descargarArchivo(archivo);

      verify(
        () => dio.download(
          url,
          '/tmp/fichas.pdf',
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).called(1);
    });

    test('si Firebase no da la URL, avisa con ServidorException', () async {
      when(() => pdf.getDownloadURL()).thenThrow(
        FirebaseException(plugin: 'firebase_storage', code: 'object-not-found'),
      );

      expect(
        remote.descargarArchivo(archivo),
        throwsA(isA<ServidorException>()),
      );
    });

    test('si la descarga se corta, avisa con ServidorException', () async {
      when(() => pdf.getDownloadURL()).thenAnswer((_) async => url);
      when(
        () => dio.download(
          any(),
          any(),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(DioException(requestOptions: RequestOptions()));

      expect(
        remote.descargarArchivo(archivo),
        throwsA(isA<ServidorException>()),
      );
    });
  });
}
