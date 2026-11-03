import 'package:app_educativa/core/database/app_database.dart';
import 'package:app_educativa/features/mascota/domain/mascota.dart';
import 'package:app_educativa/features/mascota/presentation/widgets/mascota_animada.dart';
import 'package:app_educativa/features/mascota/presentation/widgets/escenario_mascota.dart';
import 'package:app_educativa/features/perfil/data/perfil_local_datasource.dart';
import 'package:app_educativa/features/perfil/domain/perfil_estudiante.dart';
import 'package:app_educativa/features/perfil/presentation/screens/crear_perfil_screen.dart';
import 'package:app_educativa/features/progreso/data/progreso_local_datasource.dart';
import 'package:app_educativa/features/progreso/data/progreso_repository.dart';
import 'package:app_educativa/features/progreso/domain/resultado_actividad.dart';
import 'package:app_educativa/features/progreso/presentation/progreso_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/datos_prueba.dart';

void main() {
  group('evolución de la mascota', () {
    test('la etapa depende de las estrellas ganadas', () {
      expect(EtapaMascota.segunEstrellas(0), EtapaMascota.huevo);
      expect(EtapaMascota.segunEstrellas(2), EtapaMascota.huevo);
      expect(EtapaMascota.segunEstrellas(3), EtapaMascota.bebe);
      expect(EtapaMascota.segunEstrellas(15), EtapaMascota.exploradora);
      expect(EtapaMascota.segunEstrellas(40), EtapaMascota.leyenda);
      expect(EtapaMascota.segunEstrellas(500), EtapaMascota.leyenda);
    });

    test('calcula cuánto falta para la siguiente etapa', () {
      final evolucion = EvolucionMascota(9);

      expect(evolucion.etapa, EtapaMascota.bebe);
      expect(evolucion.estrellasFaltantes, 6);
      expect(evolucion.avance, 0.5);
      expect(evolucion.esUltimaEtapa, isFalse);
    });

    test('en la última etapa ya no falta nada', () {
      final evolucion = EvolucionMascota(45);

      expect(evolucion.esUltimaEtapa, isTrue);
      expect(evolucion.estrellasFaltantes, 0);
      expect(evolucion.avance, 1);
    });

    test('un identificador desconocido no es una mascota', () {
      expect(EspecieMascota.desdeId('lumi'), EspecieMascota.lumi);
      expect(EspecieMascota.desdeId('gato'), isNull);
      expect(EspecieMascota.desdeId(null), isNull);
    });
  });

  group('datos guardados', () {
    late AppDatabase base;

    setUp(() => base = crearBaseEnMemoria());
    tearDown(() => cerrarBase(base));

    test('el perfil guarda la mascota elegida', () async {
      final perfiles = PerfilLocalDataSource(appDatabase: base);

      await perfiles.guardarPerfil(
        const PerfilEstudiante(
          id: 'p1',
          nombre: 'Ana',
          mascota: EspecieMascota.burbu,
        ),
      );

      expect((await perfiles.obtenerPerfil())!.mascota, EspecieMascota.burbu);
    });

    test('un perfil sin mascota puede elegirla después', () async {
      final perfiles = PerfilLocalDataSource(appDatabase: base);
      await perfiles.guardarPerfil(
        const PerfilEstudiante(id: 'p1', nombre: 'Ana'),
      );
      expect((await perfiles.obtenerPerfil())!.mascota, isNull);

      await perfiles.guardarMascota('p1', EspecieMascota.nimbo, nombre: 'Rayo');

      final perfil = (await perfiles.obtenerPerfil())!;
      expect(perfil.mascota, EspecieMascota.nimbo);
      expect(perfil.mascotaElegida!.nombre, 'Rayo');
    });

    test('sin nombre propio la mascota se llama como su especie', () {
      expect(MascotaElegida.de(EspecieMascota.lumi).nombre, 'Lumi');
      expect(MascotaElegida.de(EspecieMascota.lumi, '   ').nombre, 'Lumi');
      expect(MascotaElegida.de(EspecieMascota.lumi, ' Sol ').nombre, 'Sol');
      expect(
        const PerfilEstudiante(id: 'p1', nombre: 'Ana').mascotaElegida,
        isNull,
      );
    });

    test('las estrellas suman los juegos completados de todos los módulos',
        () async {
      final local = ProgresoLocalDataSource(appDatabase: base);
      Future<void> registrar(
        String perfil,
        String modulo,
        String actividad, {
        required bool completada,
        required int puntaje,
      }) {
        return local.registrarResultado(
          perfilId: perfil,
          resultado: ResultadoActividad(
            moduloId: modulo,
            actividadId: actividad,
            completada: completada,
            puntaje: puntaje,
          ),
        );
      }

      await registrar('p1', 'cs-grado-1', 'a', completada: true, puntaje: 95);
      await registrar('p1', 'mt-grado-1', 'b', completada: true, puntaje: 70);
      await registrar('p1', 'mt-grado-1', 'c', completada: false, puntaje: 20);
      await registrar('otro', 'cs-grado-1', 'a', completada: true, puntaje: 95);

      final repositorio = ProgresoRepository(
        local: local,
        obtenerPerfilId: () async => 'p1',
      );

      // 3 ⭐ (95) + 2 ⭐ (70); el juego sin terminar y el otro perfil no cuentan.
      expect(await repositorio.obtenerEstrellasTotales(), 5);
    });

    test('sin perfil no hay estrellas', () async {
      final repositorio = ProgresoRepository(
        local: ProgresoLocalDataSource(appDatabase: base),
        obtenerPerfilId: () async => null,
      );

      expect(await repositorio.obtenerEstrellasTotales(), 0);
    });

    test('el controlador actualiza las estrellas al terminar un juego',
        () async {
      final controller = ProgresoController(
        repositorio: ProgresoRepository(
          local: ProgresoLocalDataSource(appDatabase: base),
          obtenerPerfilId: () async => 'p1',
        ),
      );

      await controller.cargarUltimoModulo();
      expect(controller.estrellasTotales, 0);

      await controller.registrarResultado(
        const ResultadoActividad(
          moduloId: 'cs-grado-1',
          actividadId: 'a',
          completada: true,
          puntaje: 100,
        ),
      );

      expect(controller.estrellasTotales, 3);
    });
  });

  group('pantallas', () {
    testWidgets('crear el perfil pide elegir una mascota', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CrearPerfilScreen()));

      await tester.enterText(find.byType(TextField), 'Valentina');
      await tester.ensureVisible(find.text('¡Listos, continuar!'));
      await tester.tap(find.text('¡Listos, continuar!'));
      await tester.pump();

      expect(find.text('Elige una mascota para continuar.'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('mascota-lumi')));
      await tester.tap(find.byKey(const ValueKey('mascota-lumi')));
      // La mascota elegida se mueve sin parar: no se usa pumpAndSettle.
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Elige una mascota para continuar.'), findsNothing);
      expect(find.text(EspecieMascota.lumi.descripcion), findsOneWidget);
    });

    testWidgets('el escenario avisa cuando la mascota evoluciona',
        (tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      Widget tarjeta(int? estrellas) => MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EscenarioMascota(
                  mascota: MascotaElegida.de(EspecieMascota.chispa),
                  estrellas: estrellas,
                  saludo: '¡Hola, Ana! ¿Jugamos?',
                  accion: const SizedBox.shrink(),
                ),
              ),
            ),
          );

      await tester.pumpWidget(tarjeta(null));
      await tester.pumpWidget(tarjeta(2));
      // Al abrir la app no se celebra nada.
      expect(find.textContaining('nació'), findsNothing);
      expect(
        find.text('Gana 1 estrella en los juegos para que nazca.'),
        findsOneWidget,
      );

      await tester.pumpWidget(tarjeta(4));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('✨ ¡Chispa nació! ✨'), findsOneWidget);
      expect(find.text('Bebé'), findsOneWidget);
      expect(find.text('Faltan 11 ⭐ para evolucionar.'), findsOneWidget);

      await tester.tap(find.text('✨ ¡Chispa nació! ✨'));
      await tester.pump();
      expect(find.textContaining('nació'), findsNothing);
    });

    testWidgets('se dibujan todas las mascotas en todas sus etapas',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Wrap(
              children: [
                for (final especie in EspecieMascota.values)
                  for (final etapa in EtapaMascota.values)
                    MascotaAnimada(
                      especie: especie,
                      etapa: etapa,
                      tamano: 40,
                      animada: false,
                    ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(MascotaAnimada), findsNWidgets(20));
    });
  });
}
