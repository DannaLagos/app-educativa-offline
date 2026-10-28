import 'dart:convert';
import 'dart:typed_data';

import 'package:app_educativa/core/network/servidor_exception.dart';
import 'package:app_educativa/features/modulos/data/firebase_modulo_remote_datasource.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements FirebaseStorage {}

class MockReference extends Mock implements Reference {}

void main() {
  late MockStorage storage;
  late MockReference raiz;
  late MockReference catalogo;
  late MockReference modulos;
  late MockReference carpetaModulo;
  late MockReference manifest;
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

    when(() => storage.ref('contenidos')).thenReturn(raiz);
    when(() => raiz.child('catalogo.json')).thenReturn(catalogo);
    when(() => raiz.child('modulos')).thenReturn(modulos);
    when(() => modulos.child('cs-grado-1')).thenReturn(carpetaModulo);
    when(() => carpetaModulo.child('manifest.json')).thenReturn(manifest);

    remote = FirebaseModuloRemoteDataSource(storage: storage);
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

  test('un error de Firebase se convierte en ServidorException', () async {
    when(() => catalogo.getData(any())).thenThrow(
      FirebaseException(plugin: 'firebase_storage', code: 'object-not-found'),
    );

    expect(remote.obtenerCatalogo(), throwsA(isA<ServidorException>()));
  });
}
