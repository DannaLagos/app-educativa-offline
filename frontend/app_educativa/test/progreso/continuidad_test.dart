import 'dart:io';

import 'package:app_educativa/core/database/app_database.dart';
import 'package:app_educativa/features/actividades/presentation/screens/juego_screen.dart';
import 'package:app_educativa/features/actividades/presentation/screens/mapa_niveles_screen.dart';
import 'package:app_educativa/features/modulos/data/descarga_service.dart';
import 'package:app_educativa/features/modulos/data/modulo_repository.dart';
import 'package:app_educativa/features/modulos/domain/estado_descarga.dart';
import 'package:app_educativa/features/modulos/domain/resultado_catalogo.dart';
import 'package:app_educativa/features/modulos/presentation/controllers/modulos_controller.dart';
import 'package:app_educativa/features/modulos/presentation/controllers/modulos_scope.dart';
import 'package:app_educativa/features/modulos/presentation/screens/detalle_modulo_screen.dart';
import 'package:app_educativa/features/perfil/domain/perfil_estudiante.dart';
import 'package:app_educativa/features/progreso/data/progreso_local_datasource.dart';
import 'package:app_educativa/features/progreso/data/progreso_repository.dart';
import 'package:app_educativa/features/progreso/domain/progreso_modulo.dart';
import 'package:app_educativa/features/progreso/domain/resultado_actividad.dart';
import 'package:app_educativa/features/progreso/presentation/progreso_controller.dart';
import 'package:app_educativa/features/progreso/presentation/progreso_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../actividades/datos_actividades.dart';
import '../helpers/datos_prueba.dart';

class MockModuloRepository extends Mock implements ModuloRepository {}

class MockDescargaService extends Mock implements DescargaService {}

class MockProgresoRepository extends Mock implements ProgresoRepository {}

const _perfil = 'perfil-1';

ProgresoModulo _progresoGuardado({
  int? pagina,
  List<String> juegosTerminados = const [],
}) {
  final fecha = DateTime(2026, 10, 25, 10);

  return ProgresoModulo(
    moduloId: 'cs-grado-1',
    porcentaje: 25,
    ultimaActualizacion: fecha,
    lecturas: [
      if (pagina != null)
        ProgresoLectura(
          recurso: 'CS_Grado01_Fichas.pdf',
          ultimaPagina: pagina,
          paginaMaxima: pagina,
          totalPaginas: 22,
          ultimaActualizacion: fecha,
        ),
    ],
    actividades: [
      for (final id in juegosTerminados)
        ProgresoActividad(
          actividadId: id,
          completada: true,
          puntaje: 100,
          intentos: 1,
          ultimaActualizacion: fecha,
        ),
    ],
  );
}

void main() {
  group('Último módulo usado', () {
    late AppDatabase base;
    late ProgresoLocalDataSource local;
    var ahora = DateTime(2026, 10, 25, 8);

    setUp(() {
      base = crearBaseEnMemoria();
      local = ProgresoLocalDataSource(appDatabase: base, ahora: () => ahora);
    });

    tearDown(() => cerrarBase(base));

    test('sin avance no hay módulo para continuar', () async {
      expect(await local.obtenerUltimoModuloId(_perfil), isNull);
    });

    test('es el módulo donde el estudiante avanzó por última vez', () async {
      ahora = DateTime(2026, 10, 25, 8);
      await local.guardarLectura(
        perfilId: _perfil,
        moduloId: 'cs-grado-1',
        recurso: 'fichas.pdf',
        pagina: 3,
        totalPaginas: 22,
      );

      ahora = DateTime(2026, 10, 25, 9);
      await local.registrarResultado(
        perfilId: _perfil,
        resultado: const ResultadoActividad(
          moduloId: 'lg-grado-3-01',
          actividadId: 'a1',
          completada: true,
          puntaje: 100,
        ),
      );
      expect(await local.obtenerUltimoModuloId(_perfil), 'lg-grado-3-01');

      ahora = DateTime(2026, 10, 25, 10);
      await local.guardarLectura(
        perfilId: _perfil,
        moduloId: 'cs-grado-1',
        recurso: 'fichas.pdf',
        pagina: 4,
        totalPaginas: 22,
      );
      expect(await local.obtenerUltimoModuloId(_perfil), 'cs-grado-1');
    });
  });

  test(
      'CA1, CA2 y CA3: al salir y volver a abrir la app, sin internet, '
      'recupera dónde iba', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final carpeta = await Directory.systemTemp.createTemp('continuidad_');
    addTearDown(() => carpeta.delete(recursive: true));
    final ruta = join(carpeta.path, 'app_educativa.db');

    // Primera sesión: lee hasta la página 7 y termina un juego; luego sale
    // del módulo sin completarlo y cierra la app.
    final primera = AppDatabase.conRuta(ruta);
    final antes = ProgresoController(
      repositorio: ProgresoRepository(
        local: ProgresoLocalDataSource(appDatabase: primera),
        obtenerPerfil: () async =>
            const PerfilEstudiante(id: _perfil, nombre: 'Sofía'),
      ),
    );
    await antes.guardarPagina(
      moduloId: 'cs-grado-1',
      recurso: 'fichas.pdf',
      pagina: 7,
      totalPaginas: 22,
    );
    await antes.registrarResultado(
      const ResultadoActividad(
        moduloId: 'cs-grado-1',
        actividadId: 'n1-a1-globos-cuerpo',
        completada: true,
        puntaje: 90,
      ),
    );
    await cerrarBase(primera);

    // Segunda sesión: el controlador no usa la red, solo la base local.
    final segunda = AppDatabase.conRuta(ruta);
    final despues = ProgresoController(
      repositorio: ProgresoRepository(
        local: ProgresoLocalDataSource(appDatabase: segunda),
        obtenerPerfil: () async =>
            const PerfilEstudiante(id: _perfil, nombre: 'Sofía'),
      ),
    );
    await despues.cargarUltimoModulo();

    expect(despues.ultimoModuloId, 'cs-grado-1');
    expect(
      await despues.paginaParaContinuar('cs-grado-1', 'fichas.pdf'),
      7,
    );
    expect(
      despues.progresoDe('cs-grado-1').actividadDe('n1-a1-globos-cuerpo'),
      isNotNull,
    );

    await cerrarBase(segunda);
  });

  group('Pantallas (HU08)', () {
    late MockModuloRepository modulos;
    late MockProgresoRepository progresos;
    late ModulosController modulosController;
    late ProgresoController progresoController;
    final descargado = moduloDePrueba(
      id: 'cs-grado-1',
      nombre: 'Ciencias Sociales',
      estado: EstadoDescarga.descargado,
      rutaLocal: '/datos/modulos/cs-grado-1',
    );

    setUp(() {
      modulos = MockModuloRepository();
      progresos = MockProgresoRepository();
      modulosController = ModulosController(
        repositorio: modulos,
        descargaService: MockDescargaService(),
      );
      progresoController = ProgresoController(repositorio: progresos);
      when(() => modulos.obtenerCatalogo()).thenAnswer(
        (_) async => ResultadoCatalogo(
          modulos: [descargado],
          vieneDeCache: true,
        ),
      );
    });

    Future<void> mostrar(WidgetTester tester, Widget pantalla) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await modulosController.cargarCatalogo();
      await tester.pumpWidget(
        ModulosScope(
          controller: modulosController,
          child: ProgresoScope(
            controller: progresoController,
            child: MaterialApp(home: pantalla),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('el detalle muestra el avance y ofrece seguir donde iba',
        (tester) async {
      when(() => progresos.obtenerProgresoModulo('cs-grado-1')).thenAnswer(
        (_) async => _progresoGuardado(
          pagina: 5,
          juegosTerminados: ['n1-a1-globos-cuerpo', 'n1-a2-memoria-emociones'],
        ),
      );

      await mostrar(tester, const DetalleModuloScreen(moduloId: 'cs-grado-1'));

      expect(find.text('📌 Tu avance'), findsOneWidget);
      expect(find.text('⭐ 2 juegos terminados'), findsOneWidget);
      expect(find.text('📖 Vas en la página 5 de 22'), findsOneWidget);
      expect(find.text('Seguir leyendo (página 5)'), findsOneWidget);
      expect(find.text('Seguir jugando'), findsOneWidget);
    });

    testWidgets('si no ha empezado, el detalle invita a empezar',
        (tester) async {
      when(() => progresos.obtenerProgresoModulo('cs-grado-1')).thenAnswer(
        (_) async => const ProgresoModulo.vacio('cs-grado-1'),
      );

      await mostrar(tester, const DetalleModuloScreen(moduloId: 'cs-grado-1'));

      expect(find.text('📌 Tu avance'), findsNothing);
      expect(find.text('Abrir módulo'), findsOneWidget);
      expect(find.text('Jugar y aprender'), findsOneWidget);
    });

    testWidgets('en el mapa, "Continuar donde ibas" abre el juego que sigue',
        (tester) async {
      when(() => progresos.obtenerProgresoModulo(any())).thenAnswer(
        (_) async => _progresoGuardado(juegosTerminados: [elige.id]),
      );

      await mostrar(
        tester,
        MapaNivelesScreen(modulo: descargado, cargarPlan: (_) async => plan),
      );

      expect(find.text('Nivel 1: ${parejas.titulo}'), findsOneWidget);

      await tester.tap(find.text('Continuar donde ibas'));
      await tester.pumpAndSettle();

      final juego = tester.widget<JuegoScreen>(find.byType(JuegoScreen));
      expect(juego.actividad.id, parejas.id);
    });
  });
}
