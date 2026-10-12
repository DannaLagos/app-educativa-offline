import 'dart:io';

import 'package:app_educativa/core/database/app_database.dart';
import 'package:app_educativa/core/network/conectividad_service.dart';
import 'package:app_educativa/core/network/servidor_exception.dart';
import 'package:app_educativa/features/modulos/data/almacenamiento_modulos.dart';
import 'package:app_educativa/features/modulos/data/descarga_service.dart';
import 'package:app_educativa/features/modulos/data/modulo_local_datasource.dart';
import 'package:app_educativa/features/modulos/data/modulo_remote_datasource.dart';
import 'package:app_educativa/features/modulos/domain/estado_descarga.dart';
import 'package:app_educativa/features/modulos/domain/manifest_modulo.dart';
import 'package:crypto/crypto.dart';
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
  late Directory raiz;
  late DescargaService servicio;

  final modulo = moduloDePrueba();
  final fecha = DateTime(2026, 10, 12, 9, 30);

  // Contenido "del servidor" de cada archivo.
  final archivos = <String, List<int>>{
    'parte1.pdf': List<int>.generate(300, (i) => i % 256),
    'parte2.pdf': List<int>.generate(700, (i) => (i * 7) % 256),
  };

  RecursoModulo recurso(String archivo, {String? sha}) {
    final bytes = archivos[archivo]!;
    return RecursoModulo(
      archivo: archivo,
      titulo: archivo,
      tipo: 'pdf',
      tamano: bytes.length,
      sha256: sha ?? sha256.convert(bytes).toString(),
    );
  }

  ManifestModulo manifest({String? shaParte2}) => ManifestModulo(
        id: modulo.id,
        version: 1,
        recursos: [
          recurso('parte1.pdf'),
          recurso('parte2.pdf', sha: shaParte2),
        ],
      );

  /// Simula dio.download: escribe el archivo en bloques y reporta progreso.
  /// Si [fallarEn] coincide, escribe la mitad y lanza un error de red.
  void servidorResponde({String? fallarEn}) {
    when(
      () => remote.descargarArchivo(
        moduloId: any(named: 'moduloId'),
        archivo: any(named: 'archivo'),
        destino: any(named: 'destino'),
        onRecibido: any(named: 'onRecibido'),
      ),
    ).thenAnswer((invocacion) async {
      final archivo = invocacion.namedArguments[#archivo] as String;
      final destino = invocacion.namedArguments[#destino] as String;
      final onRecibido =
          invocacion.namedArguments[#onRecibido] as void Function(int)?;
      final bytes = archivos[archivo]!;

      if (archivo == fallarEn) {
        await File(destino).writeAsBytes(bytes.sublist(0, bytes.length ~/ 2));
        throw const ServidorException('Se interrumpió la descarga.');
      }

      final salida = File(destino).openWrite();
      for (var i = 0; i < bytes.length; i += 100) {
        final fin = (i + 100).clamp(0, bytes.length);
        salida.add(bytes.sublist(i, fin));
        onRecibido?.call(fin);
      }
      await salida.close();
    });
  }

  Directory carpetaModulos() => Directory(p.join(raiz.path, 'modulos'));

  List<String> contenidoCarpetaModulos() {
    if (!carpetaModulos().existsSync()) {
      return [];
    }
    return carpetaModulos()
        .listSync()
        .map((entrada) => p.basename(entrada.path))
        .toList();
  }

  setUp(() async {
    base = crearBaseEnMemoria();
    local = ModuloLocalDataSource(appDatabase: base);
    await local.guardarCatalogo([modulo]);

    remote = MockRemote();
    conectividad = MockConectividad();
    raiz = await Directory.systemTemp.createTemp('descargas_');

    servicio = DescargaService(
      remote: remote,
      local: local,
      conectividad: conectividad,
      almacenamiento: AlmacenamientoModulos(directorioBase: () async => raiz),
      ahora: () => fecha,
    );

    when(() => conectividad.hayConexion()).thenAnswer((_) async => true);
    when(() => remote.obtenerManifest(modulo.id))
        .thenAnswer((_) async => manifest());
  });

  tearDown(() async {
    await cerrarBase(base);
    await raiz.delete(recursive: true);
  });

  test('descarga todo, informa el progreso y marca "descargado" al final',
      () async {
    servidorResponde();
    final progresos = <double>[];

    await servicio.descargar(modulo, onProgreso: progresos.add);

    final guardado = await local.obtenerModulo(modulo.id);
    final carpeta = Directory(p.join(carpetaModulos().path, modulo.id));

    expect(guardado!.estadoDescarga, EstadoDescarga.descargado);
    expect(guardado.rutaLocal, carpeta.path);
    expect(guardado.fechaDescarga, fecha);

    expect(
      File(p.join(carpeta.path, 'parte1.pdf')).readAsBytesSync(),
      archivos['parte1.pdf'],
    );
    expect(File(p.join(carpeta.path, 'parte2.pdf')).existsSync(), isTrue);
    expect(File(p.join(carpeta.path, 'manifest.json')).existsSync(), isTrue);
    expect(contenidoCarpetaModulos(), [modulo.id]);

    // El progreso empieza en 0, crece y termina en 1.
    expect(progresos.first, 0);
    expect(progresos.last, 1);
    for (var i = 1; i < progresos.length; i++) {
      expect(progresos[i], greaterThanOrEqualTo(progresos[i - 1]));
    }
    // Avance intermedio: parte1 completa (300 de 1000 bytes).
    expect(progresos, contains(closeTo(0.3, 0.001)));
  });

  test('sin conexión no intenta descargar ni cambia el estado', () async {
    when(() => conectividad.hayConexion()).thenAnswer((_) async => false);

    await expectLater(
      servicio.descargar(modulo),
      throwsA(
        isA<DescargaException>().having(
          (e) => e.motivo,
          'motivo',
          MotivoFalloDescarga.sinConexion,
        ),
      ),
    );

    verifyNever(() => remote.obtenerManifest(any()));
    final guardado = await local.obtenerModulo(modulo.id);
    expect(guardado!.estadoDescarga, EstadoDescarga.noDescargado);
  });

  test('si se corta la conexión a mitad no deja nada a medias', () async {
    servidorResponde(fallarEn: 'parte2.pdf');

    await expectLater(
      servicio.descargar(modulo),
      throwsA(
        isA<DescargaException>().having(
          (e) => e.motivo,
          'motivo',
          MotivoFalloDescarga.conexionInterrumpida,
        ),
      ),
    );

    final guardado = await local.obtenerModulo(modulo.id);
    expect(guardado!.estadoDescarga, EstadoDescarga.error);
    expect(guardado.rutaLocal, isNull);
    expect(contenidoCarpetaModulos(), isEmpty);
  });

  test('si falla el manifest marca error', () async {
    when(() => remote.obtenerManifest(modulo.id))
        .thenThrow(const ServidorException('sin respuesta'));

    await expectLater(
      servicio.descargar(modulo),
      throwsA(isA<DescargaException>()),
    );

    final guardado = await local.obtenerModulo(modulo.id);
    expect(guardado!.estadoDescarga, EstadoDescarga.error);
  });

  test('un archivo con sha256 distinto se rechaza', () async {
    servidorResponde();
    when(() => remote.obtenerManifest(modulo.id))
        .thenAnswer((_) async => manifest(shaParte2: 'abc'));

    await expectLater(
      servicio.descargar(modulo),
      throwsA(
        isA<DescargaException>().having(
          (e) => e.motivo,
          'motivo',
          MotivoFalloDescarga.archivoDanado,
        ),
      ),
    );

    final guardado = await local.obtenerModulo(modulo.id);
    expect(guardado!.estadoDescarga, EstadoDescarga.error);
    expect(contenidoCarpetaModulos(), isEmpty);
  });

  test('reintentar después de un error descarga el módulo', () async {
    servidorResponde(fallarEn: 'parte2.pdf');
    await expectLater(
      servicio.descargar(modulo),
      throwsA(isA<DescargaException>()),
    );

    servidorResponde();
    await servicio.descargar(modulo);

    final guardado = await local.obtenerModulo(modulo.id);
    expect(guardado!.estadoDescarga, EstadoDescarga.descargado);
  });

  test('al iniciar limpia descargas interrumpidas y carpetas huérfanas',
      () async {
    final otro = moduloDePrueba(id: 'lg-grado-3-02');
    final huerfano = moduloDePrueba(id: 'lg-grado-3-03');
    await local.guardarCatalogo([modulo, otro, huerfano]);

    // "modulo" quedó descargando cuando se cerró la app.
    await local.actualizarEstadoDescarga(
      modulo.id,
      EstadoDescarga.descargando,
    );
    Directory(p.join(carpetaModulos().path, '.tmp_${modulo.id}'))
        .createSync(recursive: true);

    // "otro" está descargado y su carpeta debe sobrevivir.
    final carpetaOtro = Directory(p.join(carpetaModulos().path, otro.id))
      ..createSync(recursive: true);
    await local.actualizarEstadoDescarga(
      otro.id,
      EstadoDescarga.descargado,
      rutaLocal: carpetaOtro.path,
      fechaDescarga: fecha,
    );

    // Carpeta sin módulo descargado en la base de datos.
    Directory(p.join(carpetaModulos().path, huerfano.id))
        .createSync(recursive: true);

    await servicio.limpiarIncompletas();

    expect(
      (await local.obtenerModulo(modulo.id))!.estadoDescarga,
      EstadoDescarga.error,
    );
    expect(contenidoCarpetaModulos(), [otro.id]);
  });

  test('el manifest no acepta rutas fuera de la carpeta del módulo', () {
    expect(
      () => RecursoModulo.fromJson({
        'archivo': '../../app_educativa.db',
        'titulo': 't',
        'tipo': 'pdf',
        'tamano': 1,
        'sha256': 'x',
      }),
      throwsFormatException,
    );
  });
}
