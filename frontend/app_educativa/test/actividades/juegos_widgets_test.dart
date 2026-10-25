import 'dart:math';

import 'package:app_educativa/features/actividades/domain/actividad.dart';
import 'package:app_educativa/features/actividades/domain/cuadricula_sopa.dart';
import 'package:app_educativa/features/actividades/presentation/juegos/juego_arma.dart';
import 'package:app_educativa/features/actividades/presentation/juegos/juego_arrastra.dart';
import 'package:app_educativa/features/actividades/presentation/juegos/juego_atrapa.dart';
import 'package:app_educativa/features/actividades/presentation/juegos/juego_clasifica.dart';
import 'package:app_educativa/features/actividades/presentation/juegos/juego_completa.dart';
import 'package:app_educativa/features/actividades/presentation/juegos/juego_elige.dart';
import 'package:app_educativa/features/actividades/presentation/juegos/juego_memoria.dart';
import 'package:app_educativa/features/actividades/presentation/juegos/juego_ordena.dart';
import 'package:app_educativa/features/actividades/presentation/juegos/juego_parejas.dart';
import 'package:app_educativa/features/actividades/presentation/juegos/juego_sopa.dart';
import 'package:app_educativa/features/actividades/presentation/screens/juego_screen.dart';
import 'package:app_educativa/features/actividades/presentation/screens/mapa_niveles_screen.dart';
import 'package:app_educativa/features/modulos/domain/estado_descarga.dart';
import 'package:app_educativa/features/progreso/data/progreso_repository.dart';
import 'package:app_educativa/features/progreso/domain/progreso_modulo.dart';
import 'package:app_educativa/features/progreso/domain/resultado_actividad.dart';
import 'package:app_educativa/features/progreso/presentation/progreso_controller.dart';
import 'package:app_educativa/features/progreso/presentation/progreso_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/datos_prueba.dart';
import 'datos_actividades.dart';

class MockProgresoRepository extends Mock implements ProgresoRepository {}

/// Registra lo que informa un juego.
class Registro {
  final List<bool> respuestas = [];
  var completado = false;

  void responder(bool esAcierto) => respuestas.add(esAcierto);
  void completar() => completado = true;
}

Widget _envolver(Widget hijo) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: hijo)),
  );
}

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

  // Pantalla alta para que todas las tarjetas se vean sin desplazarse.
  void pantallaAlta(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('Juego Elige', () {
    testWidgets('marca el error, deja reintentar y avanza al acertar',
        (tester) async {
      final registro = Registro();
      await tester.pumpWidget(
        _envolver(
          JuegoElige(
            actividad: elige,
            onResponder: registro.responder,
            onCompletado: registro.completar,
            random: Random(1),
            pausa: Duration.zero,
          ),
        ),
      );

      expect(find.text('¿Cuál es la mano?'), findsOneWidget);

      await tester.tap(find.text('Oreja'));
      await tester.pump();
      expect(registro.respuestas, [false]);
      expect(find.byIcon(Icons.replay_circle_filled_rounded), findsOneWidget);

      await tester.tap(find.text('Mano'));
      await tester.pumpAndSettle();
      expect(registro.respuestas, [false, true]);
      expect(find.text('¿Con qué vemos?'), findsOneWidget);

      await tester.tap(find.text('Ojos'));
      await tester.pumpAndSettle();
      expect(registro.completado, isTrue);
    });
  });

  group('Juego Parejas', () {
    testWidgets('une las parejas correctas y avisa las incorrectas',
        (tester) async {
      final registro = Registro();
      await tester.pumpWidget(
        _envolver(
          JuegoParejas(
            actividad: parejas,
            onResponder: registro.responder,
            onCompletado: registro.completar,
            random: Random(1),
            pausa: Duration.zero,
          ),
        ),
      );

      await tester.tap(find.text('Alegre'));
      await tester.tap(find.text('Una tormenta'));
      await tester.pump();
      expect(registro.respuestas, [false]);

      await tester.tap(find.text('Alegre'));
      await tester.tap(find.text('Un regalo'));
      await tester.pump();
      // Se puede empezar por cualquiera de los dos lados.
      await tester.tap(find.text('Una tormenta'));
      await tester.tap(find.text('Con miedo'));
      await tester.pumpAndSettle();

      expect(registro.respuestas, [false, true, true]);
      expect(registro.completado, isTrue);
    });
  });

  group('Juego Clasifica', () {
    testWidgets('cada tarjeta va a su canasta', (tester) async {
      pantallaAlta(tester);
      final registro = Registro();
      await tester.pumpWidget(
        _envolver(
          JuegoClasifica(
            actividad: clasifica,
            onResponder: registro.responder,
            onCompletado: registro.completar,
            random: Random(1),
            pausa: Duration.zero,
          ),
        ),
      );

      for (var i = 0; i < clasifica.tarjetas.length; i++) {
        final enPantalla = clasifica.tarjetas.firstWhere(
          (tarjeta) => find.text(tarjeta.elemento.texto).evaluate().isNotEmpty,
        );
        final otra = enPantalla.grupo == 'cuida' ? 'dana' : 'cuida';

        await tester.tap(find.byKey(ValueKey('canasta-$otra')));
        await tester.pump();
        await tester.tap(find.byKey(ValueKey('canasta-${enPantalla.grupo}')));
        await tester.pumpAndSettle();
      }

      expect(registro.respuestas, [false, true, false, true]);
      expect(registro.completado, isTrue);
    });
  });

  group('Juego Ordena', () {
    testWidgets('solo acepta el paso que sigue', (tester) async {
      pantallaAlta(tester);
      final registro = Registro();
      await tester.pumpWidget(
        _envolver(
          JuegoOrdena(
            actividad: ordena,
            onResponder: registro.responder,
            onCompletado: registro.completar,
            random: Random(1),
            pausa: Duration.zero,
          ),
        ),
      );

      expect(find.text('¿Qué va primero?'), findsOneWidget);

      await tester.tap(find.text('Cosecha'));
      await tester.pump();
      await tester.tap(find.text('Siembra'));
      await tester.pump();
      await tester.tap(find.text('Riega'));
      await tester.pump();
      await tester.tap(find.text('Cosecha'));
      await tester.pumpAndSettle();

      expect(registro.respuestas, [false, true, true, true]);
      expect(registro.completado, isTrue);
    });
  });

  group('Juego Memoria', () {
    testWidgets(
        'encontrar una pareja es acierto; fallar sin haber visto la pareja '
        'no cuenta como error, pero sí después de verla', (tester) async {
      pantallaAlta(tester);
      final registro = Registro();
      await tester.pumpWidget(
        _envolver(
          JuegoMemoria(
            actividad: memoria,
            onResponder: registro.responder,
            onCompletado: registro.completar,
            random: Random(1),
            pausa: Duration.zero,
          ),
        ),
      );

      Future<void> voltear(int pareja, int lado) async {
        await tester.tap(find.byKey(ValueKey('carta-$pareja-$lado')));
        await tester.pumpAndSettle();
      }

      // Primera vez: aún no conocía ninguna carta.
      await voltear(0, 0);
      await voltear(1, 0);
      expect(registro.respuestas, isEmpty);

      // Ya vio la Agricultora (0-0): fallar ahora con el Maíz es error.
      await voltear(0, 1);
      await voltear(1, 1);
      expect(registro.respuestas, [false]);

      await voltear(0, 0);
      await voltear(0, 1);
      await voltear(1, 0);
      await voltear(1, 1);

      expect(registro.respuestas, [false, true, true]);
      expect(registro.completado, isTrue);
    });
  });

  group('Juego Arrastra', () {
    Future<void> arrastrar(WidgetTester tester, String texto, String grupo) {
      final desde = tester.getCenter(find.text(texto));
      final hasta = tester.getCenter(find.byKey(ValueKey('destino-$grupo')));

      return tester.dragFrom(desde, hasta - desde);
    }

    testWidgets('arrastrar a la canasta correcta es acierto y a la '
        'equivocada la tarjeta regresa', (tester) async {
      pantallaAlta(tester);
      final registro = Registro();
      await tester.pumpWidget(
        _envolver(
          JuegoArrastra(
            actividad: arrastra,
            onResponder: registro.responder,
            onCompletado: registro.completar,
            random: Random(1),
            pausa: Duration.zero,
          ),
        ),
      );

      await arrastrar(tester, 'Quemar', 'cuida');
      await tester.pumpAndSettle();
      expect(registro.respuestas, [false]);
      expect(find.text('Quemar'), findsOneWidget, reason: 'regresa');

      await arrastrar(tester, 'Quemar', 'dana');
      await tester.pumpAndSettle();
      expect(find.text('Quemar'), findsNothing);

      // También funciona tocando la tarjeta y luego la canasta.
      await tester.tap(find.text('Sembrar'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('destino-cuida')));
      await tester.pumpAndSettle();

      expect(registro.respuestas, [false, true, true]);
      expect(registro.completado, isTrue);
    });
  });

  group('Juego Atrapa', () {
    testWidgets('reventar un globo correcto es acierto; uno incorrecto no',
        (tester) async {
      pantallaAlta(tester);
      final registro = Registro();
      await tester.pumpWidget(
        _envolver(
          JuegoAtrapa(
            actividad: atrapa,
            onResponder: registro.responder,
            onCompletado: registro.completar,
            random: Random(1),
            pausa: Duration.zero,
          ),
        ),
      );
      // Los globos suben solos.
      final inicio = tester.getTopLeft(find.byKey(const ValueKey('globo-0')));
      await tester.pump(const Duration(seconds: 1));
      final despues = tester.getTopLeft(find.byKey(const ValueKey('globo-0')));
      expect(despues.dy, lessThan(inicio.dy));

      await tester.tap(find.byKey(const ValueKey('globo-1'))); // Casa
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('globo-0'))); // Montaña
      await tester.pump();
      expect(find.byKey(const ValueKey('globo-0')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('globo-2'))); // Árbol
      await tester.pump();
      // Deja pasar la pausa antes de avisar que terminó.
      await tester.pump(const Duration(milliseconds: 10));

      expect(registro.respuestas, [false, true, true]);
      expect(registro.completado, isTrue);
    });
  });

  group('Juego Completa', () {
    testWidgets('tocar o arrastrar la palabra correcta completa la oración',
        (tester) async {
      pantallaAlta(tester);
      final registro = Registro();
      await tester.pumpWidget(
        _envolver(
          JuegoCompleta(
            actividad: completa,
            onResponder: registro.responder,
            onCompletado: registro.completar,
            random: Random(1),
            pausa: Duration.zero,
          ),
        ),
      );

      expect(find.text('La escuela era muy '), findsOneWidget);

      await tester.tap(find.text('corrió'));
      await tester.pump();
      await tester.tap(find.text('pequeña'));
      await tester.pumpAndSettle();
      expect(find.text('Marte es un planeta '), findsOneWidget);

      // La segunda se completa arrastrando la palabra al espacio.
      final desde = tester.getCenter(find.text('rojo'));
      final hasta = tester.getCenter(find.byKey(const ValueKey('espacio')));
      await tester.dragFrom(desde, hasta - desde);
      await tester.pumpAndSettle();

      expect(registro.respuestas, [false, true, true]);
      expect(registro.completado, isTrue);
    });
  });

  group('Juego Arma', () {
    testWidgets('las palabras se tocan en orden para armar la oración',
        (tester) async {
      pantallaAlta(tester);
      final registro = Registro();
      await tester.pumpWidget(
        _envolver(
          JuegoArma(
            actividad: arma,
            onResponder: registro.responder,
            onCompletado: registro.completar,
            random: Random(1),
            pausa: Duration.zero,
          ),
        ),
      );

      await tester.tap(find.text('ladra.'));
      await tester.pump();
      await tester.tap(find.text('El'));
      await tester.pump();
      await tester.tap(find.text('perro'));
      await tester.pump();
      await tester.tap(find.text('ladra.'));
      await tester.pumpAndSettle();

      expect(registro.respuestas, [false, true, true, true]);
      expect(registro.completado, isTrue);
    });
  });

  group('Juego Sopa de letras', () {
    testWidgets('tocar la primera y la última letra encuentra la palabra',
        (tester) async {
      pantallaAlta(tester);
      final registro = Registro();
      // La misma semilla que usa el juego, para saber dónde quedó cada una.
      final cuadricula = CuadriculaSopa.generar(
        sopa.palabras.map((palabra) => palabra.texto).toList(),
        sopa.tamano,
        Random(5),
      );

      await tester.pumpWidget(
        _envolver(
          JuegoSopa(
            actividad: sopa,
            onResponder: registro.responder,
            onCompletado: registro.completar,
            random: Random(5),
            pausa: Duration.zero,
          ),
        ),
      );

      Future<void> tocar((int, int) celda) async {
        await tester.tap(find.byKey(ValueKey('celda-${celda.$1}-${celda.$2}')));
        await tester.pump();
      }

      final luna = cuadricula.ubicaciones.firstWhere((u) => u.palabra == 'LUNA');
      final orbita =
          cuadricula.ubicaciones.firstWhere((u) => u.palabra == 'ORBITA');

      // Una línea que no es una palabra.
      await tocar(luna.inicio);
      await tocar(luna.celdas[1]);
      expect(registro.respuestas, [false]);

      // Se puede seleccionar de inicio a fin o al revés.
      await tocar(luna.inicio);
      await tocar(luna.fin);
      await tocar(orbita.fin);
      await tocar(orbita.inicio);
      await tester.pumpAndSettle();

      expect(registro.respuestas, [false, true, true]);
      expect(registro.completado, isTrue);
    });
  });

  group('Pistas', () {
    const conPista = ActividadElige(
      id: 'p1',
      titulo: 'Mi cuerpo',
      instruccion: 'Toca la respuesta.',
      pista: Pista(
        texto: '¿Puedes señalar y nombrar cada parte de tu cuerpo?',
        pagina: 9,
      ),
      preguntas: [
        PreguntaElige(
          enunciado: 'Si alguien te toca y no te gusta…',
          opciones: [
            ElementoVisual(emoji: '✋', texto: 'Digo NO'),
            ElementoVisual(emoji: '🤫', texto: 'Me callo'),
          ],
          correcta: 0,
          pista: Pista(texto: 'Tu cuerpo te pertenece.', pagina: 9),
        ),
      ],
    );

    testWidgets('el botón Pista muestra el fragmento y la página de la cartilla',
        (tester) async {
      pantallaAlta(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: JuegoScreen(
            moduloId: 'cs-grado-1',
            plan: const PlanActividades(
              niveles: [
                Nivel(
                  id: 'n',
                  numero: 1,
                  titulo: 'N',
                  emoji: '⭐',
                  objetivo: 'O',
                  actividades: [conPista],
                ),
              ],
            ),
            actividad: conPista,
            random: Random(1),
            pausa: Duration.zero,
          ),
        ),
      );

      // Una pista para la actividad y otra para la pregunta.
      expect(find.byKey(const ValueKey('boton-pista')), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('boton-pista')).first);
      await tester.pumpAndSettle();

      expect(find.text('💡 Pista de la cartilla'), findsOneWidget);
      expect(
        find.text('¿Puedes señalar y nombrar cada parte de tu cuerpo?'),
        findsOneWidget,
      );
      expect(find.text('Ver en la cartilla (página 9)'), findsOneWidget);
    });
  });

  group('Pantalla del juego (HU07)', () {
    late MockProgresoRepository repositorio;
    late ProgresoController progreso;

    setUp(() {
      repositorio = MockProgresoRepository();
      progreso = ProgresoController(repositorio: repositorio);
      when(() => repositorio.registrarResultadoActividad(any()))
          .thenAnswer((_) async {});
      when(() => repositorio.obtenerProgresoModulo(any())).thenAnswer(
        (_) async => const ProgresoModulo.vacio('cs-grado-1'),
      );
    });

    Widget app(Widget home) {
      return ProgresoScope(
        controller: progreso,
        child: MaterialApp(home: home),
      );
    }

    testWidgets(
        'CA1 y CA4: se juega en la app y muestra retroalimentación; '
        'CA3: al terminar registra el resultado', (tester) async {
      pantallaAlta(tester);
      await tester.pumpWidget(
        app(
          JuegoScreen(
            moduloId: 'cs-grado-1',
            plan: plan,
            actividad: elige,
            random: Random(1),
            pausa: Duration.zero,
          ),
        ),
      );

      expect(find.text(elige.instruccion), findsOneWidget);

      await tester.tap(find.text('Oreja'));
      await tester.pump();
      expect(
        find.textContaining(RegExp(r'Casi|Piénsalo|Tú puedes')),
        findsOneWidget,
      );

      await tester.tap(find.text('Mano'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ojos'));
      await tester.pumpAndSettle();

      final resultado = verify(
        () => repositorio.registrarResultadoActividad(captureAny()),
      ).captured.single as ResultadoActividad;
      expect(resultado.moduloId, 'cs-grado-1');
      expect(resultado.actividadId, elige.id);
      expect(resultado.completada, isTrue);
      // 2 aciertos y 1 error.
      expect(resultado.puntaje, 67);

      expect(find.text('Siguiente juego'), findsOneWidget);
      expect(find.text('Jugar otra vez'), findsOneWidget);
    });

    testWidgets('al terminar el último juego de un nivel avisa que se abrió '
        'el siguiente', (tester) async {
      pantallaAlta(tester);
      await tester.pumpWidget(
        app(
          JuegoScreen(
            moduloId: 'cs-grado-1',
            plan: plan,
            actividad: parejas,
            random: Random(1),
            pausa: Duration.zero,
          ),
        ),
      );

      await tester.tap(find.text('Alegre'));
      await tester.tap(find.text('Un regalo'));
      await tester.pump();
      await tester.tap(find.text('Con miedo'));
      await tester.tap(find.text('Una tormenta'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Abriste el nivel 2'), findsOneWidget);
    });
  });

  group('Mapa de niveles', () {
    late MockProgresoRepository repositorio;
    late ProgresoController progreso;

    setUp(() {
      repositorio = MockProgresoRepository();
      progreso = ProgresoController(repositorio: repositorio);
    });

    Future<void> mostrarMapa(
      WidgetTester tester,
      ProgresoModulo guardado,
    ) async {
      pantallaAlta(tester);
      when(() => repositorio.obtenerProgresoModulo(any()))
          .thenAnswer((_) async => guardado);

      await tester.pumpWidget(
        ProgresoScope(
          controller: progreso,
          child: MaterialApp(
            home: MapaNivelesScreen(
              modulo: moduloDePrueba(
                id: 'cs-grado-1',
                estado: EstadoDescarga.descargado,
              ),
              cargarPlan: (_) async => plan,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('al empezar solo se puede jugar el primer juego',
        (tester) async {
      await mostrarMapa(tester, const ProgresoModulo.vacio('cs-grado-1'));

      expect(find.text('Yo soy único'), findsOneWidget);
      expect(find.text('Mi región'), findsOneWidget);
      expect(find.text('Termina el nivel anterior para abrirlo.'),
          findsOneWidget);
      expect(find.text('¡Juega ahora!'), findsOneWidget);
      expect(find.text('0 de 4 juegos terminados · ⭐ 0'), findsOneWidget);

      // Un juego bloqueado no se abre.
      await tester.tap(find.byKey(ValueKey('juego-${clasifica.id}')));
      await tester.pumpAndSettle();
      expect(find.byType(JuegoScreen), findsNothing);

      await tester.tap(find.byKey(ValueKey('juego-${elige.id}')));
      await tester.pumpAndSettle();
      expect(find.byType(JuegoScreen), findsOneWidget);
    });

    testWidgets('con el nivel 1 terminado se abre el nivel 2',
        (tester) async {
      await mostrarMapa(
        tester,
        ProgresoModulo(
          moduloId: 'cs-grado-1',
          porcentaje: 0,
          ultimaActualizacion: null,
          lecturas: const [],
          actividades: [
            for (final id in [elige.id, parejas.id])
              ProgresoActividad(
                actividadId: id,
                completada: true,
                puntaje: 100,
                intentos: 1,
                ultimaActualizacion: DateTime(2026, 10, 25),
              ),
          ],
        ),
      );

      expect(find.text('Termina el nivel anterior para abrirlo.'),
          findsNothing);
      expect(find.text('2 de 4 juegos terminados · ⭐ 6'), findsOneWidget);

      await tester.tap(find.byKey(ValueKey('juego-${clasifica.id}')));
      await tester.pumpAndSettle();
      expect(find.byType(JuegoScreen), findsOneWidget);
    });

    testWidgets('un módulo sin juegos lo explica', (tester) async {
      pantallaAlta(tester);
      when(() => repositorio.obtenerProgresoModulo(any())).thenAnswer(
        (_) async => const ProgresoModulo.vacio('cs-grado-1'),
      );

      await tester.pumpWidget(
        ProgresoScope(
          controller: progreso,
          child: MaterialApp(
            home: MapaNivelesScreen(
              modulo: moduloDePrueba(id: 'cs-grado-1'),
              cargarPlan: (_) async => null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('todavía no tiene juegos'), findsOneWidget);
    });
  });
}
