import 'dart:math';

import 'package:app_educativa/core/voz/lector_voz.dart';
import 'package:app_educativa/features/actividades/data/actividades_local_datasource.dart';
import 'package:app_educativa/features/actividades/domain/actividad.dart';
import 'package:app_educativa/features/actividades/presentation/juegos/juego_bien_o_mal.dart';
import 'package:app_educativa/features/actividades/presentation/juegos/juego_elige.dart';
import 'package:app_educativa/features/actividades/presentation/juegos/juego_escucha.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Anota todo lo que se dice en voz alta.
class VozGrabada implements LectorVoz {
  final List<String> dicho = [];

  @override
  Future<void> hablar(String texto) async => dicho.add(texto);

  @override
  Future<void> detener() async {}

  @override
  Future<bool> estaDisponible() async => true;
}

class Registro {
  final List<bool> respuestas = [];
  var completado = false;

  void responder(bool esAcierto) => respuestas.add(esAcierto);
  void completar() => completado = true;
}

Widget _envolver(Widget hijo, LectorVoz voz) {
  return VozScope(
    voz: voz,
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: hijo)),
    ),
  );
}

const _bienOMal = ActividadBienOMal(
  id: 'bm',
  titulo: 'Me cuido',
  instruccion: '¿Está bien o está mal?',
  situaciones: [
    Situacion(
      elemento: ElementoVisual(
        emoji: '🗣️',
        texto: 'Contar cómo me siento',
        lectura: 'Cuando estoy triste, le cuento a alguien cómo me siento.',
      ),
      estaBien: true,
    ),
  ],
);

const _escucha = ActividadEscucha(
  id: 'es',
  titulo: 'Regalos',
  instruccion: 'Escucha y toca.',
  rondas: [
    PreguntaElige(
      enunciado: '¿Qué nos da sombra?',
      lectura: '¿Qué nos da sombra y frutas? Toca el dibujo.',
      opciones: [
        ElementoVisual(emoji: '🌳', texto: 'Árbol'),
        ElementoVisual(emoji: '🚗', texto: 'Carro'),
      ],
      correcta: 0,
    ),
  ],
);

const _elige = ActividadElige(
  id: 'el',
  titulo: 'Familia',
  instruccion: 'Toca la respuesta.',
  preguntas: [
    PreguntaElige(
      enunciado: '¿Sofía y su mamá son familia?',
      lectura: 'Sofía vive solo con su mamá. ¿Sofía tiene una familia?',
      opciones: [
        ElementoVisual(emoji: '💛', texto: 'Sí', lectura: 'Sí, es su familia'),
        ElementoVisual(emoji: '🚫', texto: 'No', lectura: 'No tiene familia'),
      ],
      correcta: 0,
    ),
  ],
);

void main() {
  void pantallaAlta(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('Contenido: texto corto en pantalla, frase completa en la voz', () {
    test('lee "lectura" de elementos y preguntas, y es opcional', () {
      final pregunta = PreguntaElige.fromJson({
        'enunciado': '¿Sofía y su mamá son familia?',
        'lectura': 'Sofía vive solo con su mamá. ¿Sofía tiene una familia?',
        'opciones': [
          {'emoji': '💛', 'texto': 'Sí', 'lectura': 'Sí, es su familia'},
          {'emoji': '🚫', 'texto': 'No'},
        ],
        'correcta': 0,
      });

      expect(pregunta.paraLeer, startsWith('Sofía vive solo'));
      expect(pregunta.opciones[0].paraLeer, 'Sí, es su familia');
      // Sin "lectura", la voz dice el mismo texto de la pantalla.
      expect(pregunta.opciones[1].paraLeer, 'No');
    });

    test('lee los juegos "¿Bien o mal?" y "Escucha y toca"', () {
      final bienOMal = Actividad.fromJson({
        'id': 'bm',
        'tipo': 'bienomal',
        'titulo': 'Me cuido',
        'instruccion': '¿Está bien o está mal?',
        'situaciones': [
          {'emoji': '💥', 'texto': 'Romper cosas', 'bien': false},
          {'emoji': '🗣️', 'texto': 'Contar', 'lectura': 'Le cuento', 'bien': true},
        ],
      }) as ActividadBienOMal;
      final escucha = Actividad.fromJson({
        'id': 'es',
        'tipo': 'escucha',
        'titulo': 'Regalos',
        'instruccion': 'Escucha y toca.',
        'rondas': [
          {
            'enunciado': '¿Qué nos da sombra?',
            'opciones': [
              {'emoji': '🌳', 'texto': 'Árbol'},
              {'emoji': '🚗', 'texto': 'Carro'},
            ],
            'correcta': 0,
          },
        ],
      }) as ActividadEscucha;

      expect(bienOMal.totalAciertos, 2);
      expect(bienOMal.situaciones.map((s) => s.estaBien), [false, true]);
      expect(bienOMal.situaciones[1].elemento.paraLeer, 'Le cuento');
      expect(escucha.totalAciertos, 1);
      expect(escucha.rondas.single.respuesta.texto, 'Árbol');
    });

    test('una situación sin "bien" es un error del contenido', () {
      expect(
        () => Situacion.fromJson({'emoji': '💥', 'texto': 'Romper cosas'}),
        throwsFormatException,
      );
    });

    test('Sociales 1°: textos cortos y juegos que no exigen leer', () async {
      final plan = await const ActividadesLocalDataSource().leerArchivo(
        '../../backend/contenidos/modulos/cs-grado-1/actividades.json',
      );
      int palabras(String texto) => texto.trim().split(RegExp(r'\s+')).length;

      final enPantalla = <String>[
        for (final actividad in plan.actividades)
          ...switch (actividad) {
            ActividadElige(:final preguntas) ||
            ActividadEscucha(rondas: final preguntas) =>
              [
                for (final p in preguntas) ...p.opciones.map((o) => o.texto),
              ],
            ActividadBienOMal(:final situaciones) =>
              situaciones.map((s) => s.elemento.texto),
            ActividadArrastra(:final tarjetas) =>
              tarjetas.map((t) => t.elemento.texto),
            ActividadOrdena(:final pasos) => pasos.map((p) => p.texto),
            ActividadMemoria(:final pares) => [
                for (final p in pares) ...[p.izquierda.texto, p.derecha.texto],
              ],
            _ => const <String>[],
          },
      ];
      final largos = enPantalla.where((texto) => palabras(texto) > 5);

      expect(largos, isEmpty, reason: 'Lo largo va en "lectura".');
      expect(
        plan.actividades.map((actividad) => actividad.tipo),
        containsAll([TipoActividad.bienOMal, TipoActividad.escucha]),
      );
    });
  });

  group('Juego ¿Bien o mal?', () {
    testWidgets('dice la frase completa y acepta solo la respuesta correcta',
        (tester) async {
      pantallaAlta(tester);
      final voz = VozGrabada();
      final registro = Registro();
      await tester.pumpWidget(
        _envolver(
          JuegoBienOMal(
            actividad: _bienOMal,
            onResponder: registro.responder,
            onCompletado: registro.completar,
            random: Random(1),
            pausa: Duration.zero,
          ),
          voz,
        ),
      );

      expect(voz.dicho.single, startsWith('Cuando estoy triste'));
      expect(find.text('Contar cómo me siento'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('boton-mal')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('boton-bien')));
      await tester.pumpAndSettle();

      expect(registro.respuestas, [false, true]);
      expect(registro.completado, isTrue);
    });
  });

  group('Juego Escucha y toca', () {
    testWidgets('dice qué buscar y se puede volver a escuchar',
        (tester) async {
      pantallaAlta(tester);
      final voz = VozGrabada();
      final registro = Registro();
      await tester.pumpWidget(
        _envolver(
          JuegoEscucha(
            actividad: _escucha,
            onResponder: registro.responder,
            onCompletado: registro.completar,
            random: Random(1),
            pausa: Duration.zero,
          ),
          voz,
        ),
      );

      expect(voz.dicho, ['¿Qué nos da sombra y frutas? Toca el dibujo.']);

      await tester.tap(find.byKey(const ValueKey('boton-escuchar')));
      await tester.pump();
      expect(voz.dicho, hasLength(2));

      await tester.tap(find.text('Carro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Árbol'));
      await tester.pumpAndSettle();

      expect(registro.respuestas, [false, true]);
      expect(registro.completado, isTrue);
    });
  });

  group('Elige con lectura asistida', () {
    testWidgets('lee la pregunta y cada opción en orden, con su 🔊',
        (tester) async {
      pantallaAlta(tester);
      final voz = VozGrabada();
      final registro = Registro();
      await tester.pumpWidget(
        _envolver(
          JuegoElige(
            actividad: _elige,
            onResponder: registro.responder,
            onCompletado: registro.completar,
            random: Random(1),
            pausa: Duration.zero,
            lecturaAsistida: true,
          ),
          voz,
        ),
      );
      await tester.pump();

      // Pregunta completa y luego las dos opciones (en el orden mezclado).
      expect(voz.dicho.first, startsWith('Sofía vive solo'));
      expect(
        voz.dicho.skip(1).toSet(),
        {'Sí, es su familia', 'No tiene familia'},
      );

      // Cada opción tiene su botón para escucharla sin responder.
      expect(find.byTooltip('Escuchar'), findsNWidgets(2));
      await tester.tap(find.byTooltip('Escuchar').first);
      await tester.pump();
      expect(registro.respuestas, isEmpty);

      await tester.tap(find.text('Sí'));
      await tester.pumpAndSettle();
      expect(registro.respuestas, [true]);
      expect(registro.completado, isTrue);
    });

    testWidgets('sin lectura asistida solo lee la pregunta', (tester) async {
      pantallaAlta(tester);
      final voz = VozGrabada();
      await tester.pumpWidget(
        _envolver(
          JuegoElige(
            actividad: _elige,
            onResponder: (_) {},
            onCompletado: () {},
            random: Random(1),
            pausa: Duration.zero,
          ),
          voz,
        ),
      );
      await tester.pump();

      expect(voz.dicho, [_elige.preguntas.single.paraLeer]);
      expect(find.byTooltip('Escuchar'), findsNothing);
    });
  });
}
