import 'dart:math';

import 'package:app_educativa/core/database/app_database.dart';
import 'package:app_educativa/features/actividades/presentation/screens/juego_screen.dart';
import 'package:app_educativa/features/mascota/domain/mascota.dart';
import 'package:app_educativa/features/mascota/presentation/mascota_scope.dart';
import 'package:app_educativa/features/mascota/presentation/widgets/ceremonia_evolucion.dart';
import 'package:app_educativa/features/mascota/presentation/widgets/escenario_mascota.dart';
import 'package:app_educativa/features/mascota/presentation/widgets/mascota_animada.dart';
import 'package:app_educativa/features/perfil/presentation/screens/crear_perfil_screen.dart';
import 'package:app_educativa/features/progreso/data/progreso_local_datasource.dart';
import 'package:app_educativa/features/progreso/data/progreso_repository.dart';
import 'package:app_educativa/features/progreso/domain/progreso_modulo.dart';
import 'package:app_educativa/features/progreso/domain/resultado_actividad.dart';
import 'package:app_educativa/features/progreso/presentation/progreso_controller.dart';
import 'package:app_educativa/features/progreso/presentation/progreso_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../actividades/datos_actividades.dart';
import '../helpers/datos_prueba.dart';

class MockProgresoRepository extends Mock implements ProgresoRepository {}

/// Sin animaciones: la mascota se mueve sin parar y así las pruebas terminan.
Widget _quieto(Widget hijo) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: hijo,
  );
}

void _pantallaAlta(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

final Finder _mascotaTocable = find.byWidgetPredicate(
  (widget) => widget is MascotaAnimada && widget.onTocar != null,
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      const ResultadoActividad(
        moduloId: 'm',
        actividadId: 'a',
        completada: true,
        puntaje: 0,
      ),
    );
  });

  group('escenario', () {
    Widget escenario({int estrellas = 2, bool dormida = false}) {
      return _quieto(
        Scaffold(
          body: SingleChildScrollView(
            child: EscenarioMascota(
              mascota: MascotaElegida.de(EspecieMascota.lumi, 'Sol'),
              estrellas: estrellas,
              saludo: '¡Hola, Ana! ¿Jugamos?',
              dormida: dormida,
              accion: const SizedBox.shrink(),
            ),
          ),
        ),
      );
    }

    testWidgets('al tocar la mascota dice frases distintas', (tester) async {
      _pantallaAlta(tester);
      await tester.pumpWidget(escenario());

      expect(find.text('¡Hola, Ana! ¿Jugamos?'), findsOneWidget);

      await tester.tap(_mascotaTocable);
      await tester.pump();
      expect(find.text('¡Me encanta jugar contigo!'), findsOneWidget);

      await tester.tap(_mascotaTocable);
      await tester.pump();
      expect(find.text('¡Jiji, me haces cosquillas!'), findsOneWidget);
    });

    testWidgets('la silueta cuenta cuánto falta para la próxima forma',
        (tester) async {
      _pantallaAlta(tester);
      await tester.pumpWidget(escenario(estrellas: 9));

      await tester.tap(find.byKey(const ValueKey('proxima-forma')));
      await tester.pump();

      expect(
        find.text('¡Es una sorpresa! Con 6 estrellas más seré Exploradora.'),
        findsOneWidget,
      );
    });

    testWidgets('en la última etapa no hay silueta', (tester) async {
      _pantallaAlta(tester);
      await tester.pumpWidget(escenario(estrellas: 45));

      expect(find.byKey(const ValueKey('proxima-forma')), findsNothing);
    });

    testWidgets('dormida, despierta al tocarla', (tester) async {
      _pantallaAlta(tester);
      await tester.pumpWidget(escenario(dormida: true));

      expect(find.textContaining('Sol está durmiendo'), findsOneWidget);
      expect(
        tester.widget<MascotaAnimada>(_mascotaTocable).expresion,
        ExpresionMascota.dormida,
      );

      await tester.tap(_mascotaTocable);
      await tester.pump();

      expect(find.text('¡Ya desperté! ¡Te extrañé mucho!'), findsOneWidget);
      expect(
        tester.widget<MascotaAnimada>(_mascotaTocable).expresion,
        ExpresionMascota.normal,
      );
    });
  });

  group('en el juego', () {
    late MockProgresoRepository repositorio;
    late int estrellasGuardadas;

    setUp(() {
      repositorio = MockProgresoRepository();
      estrellasGuardadas = 2;
      when(() => repositorio.obtenerEstrellasTotales())
          .thenAnswer((_) async => estrellasGuardadas);
      when(() => repositorio.obtenerUltimaActividad())
          .thenAnswer((_) async => null);
      when(() => repositorio.obtenerUltimoModulo())
          .thenAnswer((_) async => null);
      when(() => repositorio.obtenerProgresoModulo(any()))
          .thenAnswer((invocacion) async => ProgresoModulo.vacio(
                invocacion.positionalArguments.first as String,
              ));
      when(() => repositorio.registrarResultadoActividad(any()))
          .thenAnswer((_) async => estrellasGuardadas += 2);
    });

    Future<void> abrirJuego(WidgetTester tester) async {
      final controller = ProgresoController(repositorio: repositorio);
      await controller.cargarUltimoModulo();

      await tester.pumpWidget(
        ProgresoScope(
          controller: controller,
          child: MascotaScope(
            mascota: ValueNotifier(
              MascotaElegida.de(EspecieMascota.lumi, 'Sol'),
            ),
            child: _quieto(
              JuegoScreen(
                moduloId: 'cs-grado-1',
                plan: plan,
                actividad: elige,
                random: Random(1),
                pausa: Duration.zero,
              ),
            ),
          ),
        ),
      );
    }

    MascotaAnimada mascotaDelJuego(WidgetTester tester) {
      return tester.widget<MascotaAnimada>(find.byType(MascotaAnimada));
    }

    testWidgets('tras un error la mascota da ánimo hasta el siguiente acierto',
        (tester) async {
      _pantallaAlta(tester);
      await abrirJuego(tester);

      expect(mascotaDelJuego(tester).expresion, ExpresionMascota.normal);

      await tester.tap(find.text('Oreja'));
      await tester.pump();
      expect(mascotaDelJuego(tester).expresion, ExpresionMascota.animo);

      await tester.tap(find.text('Mano'));
      await tester.pump();
      expect(mascotaDelJuego(tester).expresion, ExpresionMascota.normal);
      // Deja pasar la pausa antes de la siguiente pregunta.
      await tester.pumpAndSettle();
    });

    testWidgets('si la mascota cambia de etapa, se celebra con la ceremonia',
        (tester) async {
      _pantallaAlta(tester);
      await abrirJuego(tester);

      await tester.tap(find.text('Mano'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ojos'));
      await tester.pumpAndSettle();

      // 2 ⭐ antes y 4 ⭐ después: el huevo nace.
      expect(find.byType(CeremoniaEvolucion), findsOneWidget);
      expect(find.text('¡Sol nació!'), findsOneWidget);

      await tester.tap(find.text('¡Genial!'));
      await tester.pumpAndSettle();

      expect(find.byType(CeremoniaEvolucion), findsNothing);
      expect(find.textContaining('para Sol'), findsOneWidget);
    });

    testWidgets('sin cambio de etapa no hay ceremonia', (tester) async {
      estrellasGuardadas = 5;
      _pantallaAlta(tester);
      await abrirJuego(tester);

      await tester.tap(find.text('Mano'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ojos'));
      await tester.pumpAndSettle();

      expect(find.byType(CeremoniaEvolucion), findsNothing);
      expect(find.textContaining('para Sol'), findsOneWidget);
    });
  });

  group('nombre al crear el perfil', () {
    TextField campoNombreMascota(WidgetTester tester) {
      return tester.widget<TextField>(
        find.byKey(const ValueKey('nombre-mascota')),
      );
    }

    testWidgets('se llena con la especie y se cambia tocando una sugerencia',
        (tester) async {
      _pantallaAlta(tester);
      await tester.pumpWidget(_quieto(const CrearPerfilScreen()));

      expect(find.text('Ponle un nombre'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('mascota-lumi')));
      await tester.pump();

      expect(find.text('Ponle un nombre'), findsOneWidget);
      expect(campoNombreMascota(tester).controller!.text, 'Lumi');

      await tester.ensureVisible(find.text('Estrellita'));
      await tester.tap(find.text('Estrellita'));
      await tester.pump();
      expect(campoNombreMascota(tester).controller!.text, 'Estrellita');

      // Era una sugerencia: al cambiar de mascota toma el nuevo nombre.
      await tester.ensureVisible(find.byKey(const ValueKey('mascota-chispa')));
      await tester.tap(find.byKey(const ValueKey('mascota-chispa')));
      await tester.pump();
      expect(campoNombreMascota(tester).controller!.text, 'Chispa');

      // Un nombre escrito por el niño se respeta.
      await tester.enterText(
        find.byKey(const ValueKey('nombre-mascota')),
        'Pepito',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('mascota-burbu')));
      await tester.tap(find.byKey(const ValueKey('mascota-burbu')));
      await tester.pump();
      expect(campoNombreMascota(tester).controller!.text, 'Pepito');
    });
  });

  group('última actividad', () {
    late AppDatabase base;

    setUp(() => base = crearBaseEnMemoria());
    tearDown(() => cerrarBase(base));

    test('es la fecha del avance más reciente del perfil', () async {
      var ahora = DateTime(2026, 10, 1, 9);
      final local = ProgresoLocalDataSource(
        appDatabase: base,
        ahora: () => ahora,
      );

      expect(await local.obtenerUltimaActividad('p1'), isNull);

      Future<void> registrar(String perfil, String modulo) {
        return local.registrarResultado(
          perfilId: perfil,
          resultado: ResultadoActividad(
            moduloId: modulo,
            actividadId: 'a',
            completada: true,
            puntaje: 90,
          ),
        );
      }

      await registrar('p1', 'cs-grado-1');
      ahora = DateTime(2026, 10, 3, 9);
      await registrar('p1', 'mt-grado-1');
      ahora = DateTime(2026, 10, 9, 9);
      await registrar('otro', 'cs-grado-1');

      expect(
        await local.obtenerUltimaActividad('p1'),
        DateTime(2026, 10, 3, 9),
      );
    });
  });
}
