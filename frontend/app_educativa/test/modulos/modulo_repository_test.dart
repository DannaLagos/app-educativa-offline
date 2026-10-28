import 'dart:convert';
import 'dart:io';

import 'package:app_educativa/core/database/app_database.dart';
import 'package:app_educativa/core/network/conectividad_service.dart';
import 'package:app_educativa/core/network/servidor_exception.dart';
import 'package:app_educativa/features/modulos/data/almacenamiento_modulos.dart';
import 'package:app_educativa/features/modulos/data/modulo_local_datasource.dart';
import 'package:app_educativa/features/modulos/data/modulo_remote_datasource.dart';
import 'package:app_educativa/features/modulos/data/modulo_repository.dart';
import 'package:app_educativa/features/modulos/domain/estado_descarga.dart';
import 'package:app_educativa/features/modulos/domain/modulo.dart';
import 'package:app_educativa/features/modulos/domain/contenido_incompleto_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

import '../helpers/datos_prueba.dart';

class MockRemote extends Mock implements ModuloRemoteDataSource {}

class MockConectividad extends Mock implements ConectividadService {}

void main() {
  late AppDatabase base;
  late ModuloLocalDataSource local;
  late MockRemote remote;
  late MockConectividad conectividad;
  late ModuloRepository repositorio;
  late Directory raiz;

  final sociales = moduloDePrueba(
    id: 'cs-grado-1',
    nombre: 'Ciencias Sociales',
    area: 'Ciencias Sociales',
    grado: 1,
  );
  final lenguaje = moduloDePrueba();

  setUp(() async {
    raiz = await Directory.systemTemp.createTemp('repo_');
    base = crearBaseEnMemoria();
    local = ModuloLocalDataSource(appDatabase: base);
    remote = MockRemote();
    conectividad = MockConectividad();
    repositorio = ModuloRepository(
      remote: remote,
      local: local,
      conectividad: conectividad,
      almacenamiento: AlmacenamientoModulos(directorioBase: () async => raiz),
    );
  });

  tearDown(() async {
    await cerrarBase(base);
    await raiz.delete(recursive: true);
  });

  test('con conexión trae el catálogo del servidor y lo guarda', () async {
    when(() => conectividad.hayConexion()).thenAnswer((_) async => true);
    when(() => remote.obtenerCatalogo())
        .thenAnswer((_) async => [lenguaje, sociales]);

    final resultado = await repositorio.obtenerCatalogo();

    expect(resultado.vieneDeCache, isFalse);
    expect(
      resultado.modulos.map((m) => m.id),
      ['cs-grado-1', 'lg-grado-3-01'],
    );
    expect(await local.obtenerModulo('lg-grado-3-01'), isNotNull);
  });

  test('sin conexión muestra el catálogo guardado sin llamar al servidor',
      () async {
    await local.guardarCatalogo([sociales, lenguaje]);
    when(() => conectividad.hayConexion()).thenAnswer((_) async => false);

    final resultado = await repositorio.obtenerCatalogo();

    expect(resultado.vieneDeCache, isTrue);
    expect(resultado.modulos, hasLength(2));
    verifyNever(() => remote.obtenerCatalogo());
  });

  test('si el servidor falla usa el catálogo guardado', () async {
    await local.guardarCatalogo([sociales]);
    when(() => conectividad.hayConexion()).thenAnswer((_) async => true);
    when(() => remote.obtenerCatalogo())
        .thenThrow(const ServidorException('sin respuesta'));

    final resultado = await repositorio.obtenerCatalogo();

    expect(resultado.vieneDeCache, isTrue);
    expect(resultado.modulos.single.id, 'cs-grado-1');
  });

  test('actualizar el catálogo no borra el estado de descarga', () async {
    await local.guardarCatalogo([lenguaje]);
    final db = await base.database;
    await db.update(
      'modulo',
      {
        'estado_descarga': EstadoDescarga.descargado.valor,
        'ruta_local': '/datos/modulos/lg-grado-3-01',
      },
    );

    when(() => conectividad.hayConexion()).thenAnswer((_) async => true);
    when(() => remote.obtenerCatalogo()).thenAnswer(
      (_) async => [moduloDePrueba(nombre: 'Lenguaje - Nombre nuevo')],
    );

    final resultado = await repositorio.obtenerCatalogo();
    final modulo = resultado.modulos.single;

    expect(modulo.nombre, 'Lenguaje - Nombre nuevo');
    expect(modulo.estadoDescarga, EstadoDescarga.descargado);
    expect(modulo.rutaLocal, '/datos/modulos/lg-grado-3-01');
  });

  test('solo muestra módulos habilitados', () async {
    when(() => conectividad.hayConexion()).thenAnswer((_) async => true);
    when(() => remote.obtenerCatalogo()).thenAnswer(
      (_) async => [
        sociales,
        moduloDePrueba(estaHabilitado: false),
      ],
    );

    final resultado = await repositorio.obtenerCatalogo();

    expect(resultado.modulos.map((m) => m.id), ['cs-grado-1']);
  });

  test('un módulo que sale del catálogo queda deshabilitado, no borrado',
      () async {
    await local.guardarCatalogo([sociales, lenguaje]);
    when(() => conectividad.hayConexion()).thenAnswer((_) async => true);
    when(() => remote.obtenerCatalogo()).thenAnswer((_) async => [sociales]);

    final resultado = await repositorio.obtenerCatalogo();

    expect(resultado.modulos.map((m) => m.id), ['cs-grado-1']);
    final guardado = await local.obtenerModulo('lg-grado-3-01');
    expect(guardado, isNotNull);
    expect(guardado!.estaHabilitado, isFalse);
  });

  group('acceso offline (HU04)', () {
    late Directory carpeta;

    Future<void> descargarEnDisco() async {
      carpeta = Directory(p.join(raiz.path, 'modulos', lenguaje.id))
        ..createSync(recursive: true);
      File(p.join(carpeta.path, 'leccion.pdf')).writeAsBytesSync([1, 2, 3]);
      File(p.join(carpeta.path, 'manifest.json')).writeAsStringSync(
        jsonEncode({
          'id': lenguaje.id,
          'version': 1,
          'recursos': [
            {
              'archivo': 'leccion.pdf',
              'titulo': 'Lección 1',
              'tipo': 'pdf',
              'tamano': 3,
              'sha256': 'x',
            },
          ],
        }),
      );

      await local.guardarCatalogo([lenguaje]);
      await local.actualizarEstadoDescarga(
        lenguaje.id,
        EstadoDescarga.descargado,
        rutaLocal: carpeta.path,
        fechaDescarga: DateTime(2026, 10, 12),
      );
    }

    test('lee los recursos solo del dispositivo, sin red', () async {
      await descargarEnDisco();
      final modulo = (await local.obtenerModulo(lenguaje.id))!;

      final recursos = await repositorio.obtenerRecursosLocales(modulo);

      expect(recursos.single.titulo, 'Lección 1');
      expect(recursos.single.ruta, p.join(carpeta.path, 'leccion.pdf'));
      // No consulta la conexión ni el servidor: funciona en modo avión.
      verifyZeroInteractions(conectividad);
      verifyZeroInteractions(remote);
    });

    test('si faltan archivos avisa y marca el módulo para descargarlo de nuevo',
        () async {
      await descargarEnDisco();
      File(p.join(carpeta.path, 'leccion.pdf')).deleteSync();
      final modulo = (await local.obtenerModulo(lenguaje.id))!;

      await expectLater(
        repositorio.obtenerRecursosLocales(modulo),
        throwsA(isA<ContenidoIncompletoException>()),
      );
      expect(
        (await local.obtenerModulo(lenguaje.id))!.estadoDescarga,
        EstadoDescarga.error,
      );
    });

    test('un módulo no descargado no se puede abrir', () async {
      await expectLater(
        repositorio.obtenerRecursosLocales(lenguaje),
        throwsA(isA<ContenidoIncompletoException>()),
      );
    });
  });

  group('gestión de descargas (HU05)', () {
    Future<Directory> descargar(String id) async {
      final carpeta = Directory(p.join(raiz.path, 'modulos', id))
        ..createSync(recursive: true);
      File(p.join(carpeta.path, 'leccion.pdf')).writeAsBytesSync([1, 2, 3]);
      await local.actualizarEstadoDescarga(
        id,
        EstadoDescarga.descargado,
        rutaLocal: carpeta.path,
        fechaDescarga: DateTime(2026, 10, 12),
      );
      return carpeta;
    }

    test('eliminar borra los archivos y el módulo sigue en el catálogo',
        () async {
      await local.guardarCatalogo([sociales, lenguaje]);
      final carpeta = await descargar(lenguaje.id);
      final modulo = (await local.obtenerModulo(lenguaje.id))!;

      await repositorio.eliminarDescarga(modulo);

      expect(carpeta.existsSync(), isFalse);
      expect(await repositorio.obtenerDescargados(), isEmpty);

      when(() => conectividad.hayConexion()).thenAnswer((_) async => false);
      final catalogo = await repositorio.obtenerCatalogo();
      final enCatalogo = catalogo.modulos.singleWhere(
        (m) => m.id == lenguaje.id,
      );
      expect(enCatalogo.estadoDescarga, EstadoDescarga.noDescargado);
      expect(enCatalogo.rutaLocal, isNull);
      expect(enCatalogo.fechaDescarga, isNull);
    });

    test('eliminar NUNCA borra el progreso del estudiante', () async {
      await local.guardarCatalogo([lenguaje]);
      await descargar(lenguaje.id);
      final db = await base.database;
      await db.insert('progreso_modulo', {
        'id': 'pr-1',
        'perfil_id': 'perfil-1',
        'modulo_id': lenguaje.id,
        'porcentaje': 40,
        'ultima_actualizacion': '2026-10-12T10:00:00.000',
      });

      await repositorio.eliminarDescarga(
        (await local.obtenerModulo(lenguaje.id))!,
      );

      expect(await db.query('progreso_modulo'), [
        {
          'id': 'pr-1',
          'perfil_id': 'perfil-1',
          'modulo_id': lenguaje.id,
          'porcentaje': 40,
          'ultima_actualizacion': '2026-10-12T10:00:00.000',
          'sincronizado': 0,
        },
      ]);
      // La fila del módulo tampoco se borra.
      expect(await local.obtenerModulo(lenguaje.id), isNotNull);
    });

    test('un módulo deshabilitado pero descargado sigue en Mis descargas',
        () async {
      await local.guardarCatalogo([sociales, lenguaje]);
      await descargar(lenguaje.id);
      // El servidor deja de publicar "lenguaje".
      await local.guardarCatalogo([sociales]);

      final descargados = await repositorio.obtenerDescargados();

      expect(descargados.single.id, lenguaje.id);
      expect(descargados.single.estaHabilitado, isFalse);
    });

    test('Mis descargas solo lista los módulos descargados', () async {
      await local.guardarCatalogo([sociales, lenguaje]);
      await descargar(sociales.id);

      final descargados = await repositorio.obtenerDescargados();

      expect(descargados.map((m) => m.id), [sociales.id]);
    });
  });

  group('versiones nuevas', () {
    Future<void> descargadoEnVersion(int version) async {
      await local.guardarCatalogo([lenguaje]);
      await local.actualizarEstadoDescarga(
        lenguaje.id,
        EstadoDescarga.descargado,
        rutaLocal: '/datos/modulos/${lenguaje.id}',
        fechaDescarga: DateTime(2026, 10, 12),
        versionDescargada: version,
      );
    }

    Future<Modulo> sincronizarConVersion(int version) async {
      when(() => conectividad.hayConexion()).thenAnswer((_) async => true);
      when(() => remote.obtenerCatalogo()).thenAnswer(
        (_) async => [moduloDePrueba(version: version)],
      );
      return (await repositorio.obtenerCatalogo()).modulos.single;
    }

    test('avisa cuando el catálogo trae una versión mayor', () async {
      await descargadoEnVersion(1);

      final modulo = await sincronizarConVersion(2);

      expect(modulo.estadoDescarga, EstadoDescarga.descargado);
      expect(modulo.versionDescargada, 1);
      expect(modulo.tieneActualizacion, isTrue);
    });

    test('no avisa si la versión descargada es la del catálogo', () async {
      await descargadoEnVersion(2);

      final modulo = await sincronizarConVersion(2);

      expect(modulo.tieneActualizacion, isFalse);
    });

    test('un módulo descargado sin versión conocida se trata como antiguo',
        () async {
      await local.guardarCatalogo([lenguaje]);
      await local.actualizarEstadoDescarga(
        lenguaje.id,
        EstadoDescarga.descargado,
        rutaLocal: '/datos/modulos/${lenguaje.id}',
      );

      final modulo = await sincronizarConVersion(1);

      expect(modulo.tieneActualizacion, isTrue);
    });
  });

  test('un módulo deshabilitado no muestra aviso de versión nueva', () async {
    await local.guardarCatalogo([lenguaje]);
    await local.actualizarEstadoDescarga(
      lenguaje.id,
      EstadoDescarga.descargado,
      rutaLocal: '/datos/modulos/${lenguaje.id}',
    );
    // El servidor lo retira del catálogo.
    await local.guardarCatalogo([sociales]);

    final descargado = (await repositorio.obtenerDescargados()).single;

    expect(descargado.estaHabilitado, isFalse);
    expect(descargado.tieneActualizacion, isFalse);
  });
}
