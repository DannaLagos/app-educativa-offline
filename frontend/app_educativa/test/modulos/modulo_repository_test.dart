import 'package:app_educativa/core/database/app_database.dart';
import 'package:app_educativa/core/network/conectividad_service.dart';
import 'package:app_educativa/core/network/servidor_exception.dart';
import 'package:app_educativa/features/modulos/data/modulo_local_datasource.dart';
import 'package:app_educativa/features/modulos/data/modulo_remote_datasource.dart';
import 'package:app_educativa/features/modulos/data/modulo_repository.dart';
import 'package:app_educativa/features/modulos/domain/estado_descarga.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/datos_prueba.dart';

class MockRemote extends Mock implements ModuloRemoteDataSource {}

class MockConectividad extends Mock implements ConectividadService {}

void main() {
  late AppDatabase base;
  late ModuloLocalDataSource local;
  late MockRemote remote;
  late MockConectividad conectividad;
  late ModuloRepository repositorio;

  final sociales = moduloDePrueba(
    id: 'cs-grado-1',
    nombre: 'Ciencias Sociales',
    area: 'Ciencias Sociales',
    grado: 1,
  );
  final lenguaje = moduloDePrueba();

  setUp(() {
    base = crearBaseEnMemoria();
    local = ModuloLocalDataSource(appDatabase: base);
    remote = MockRemote();
    conectividad = MockConectividad();
    repositorio = ModuloRepository(
      remote: remote,
      local: local,
      conectividad: conectividad,
    );
  });

  tearDown(() => cerrarBase(base));

  test('con conexión trae el catálogo del servidor y lo guarda', () async {
    when(() => conectividad.hayConexion()).thenAnswer((_) async => true);
    when(() => remote.obtenerCatalogo())
        .thenAnswer((_) async => [lenguaje, sociales]);

    final resultado = await repositorio.obtenerCatalogo();

    expect(resultado.desdeCache, isFalse);
    // Ordenado por área y grado.
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

    expect(resultado.desdeCache, isTrue);
    expect(resultado.modulos, hasLength(2));
    verifyNever(() => remote.obtenerCatalogo());
  });

  test('si el servidor falla usa el catálogo guardado', () async {
    await local.guardarCatalogo([sociales]);
    when(() => conectividad.hayConexion()).thenAnswer((_) async => true);
    when(() => remote.obtenerCatalogo())
        .thenThrow(const ServidorException('sin respuesta'));

    final resultado = await repositorio.obtenerCatalogo();

    expect(resultado.desdeCache, isTrue);
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
        moduloDePrueba(habilitado: false),
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
    expect(guardado!.habilitado, isFalse);
  });
}
