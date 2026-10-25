import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app_educativa/features/actividades/data/actividades_local_datasource.dart';
import 'package:app_educativa/features/actividades/domain/actividad.dart';
import 'package:app_educativa/features/actividades/domain/cuadricula_sopa.dart';
import 'package:app_educativa/features/actividades/domain/ruta_aprendizaje.dart';
import 'package:app_educativa/features/modulos/domain/recurso_local.dart';
import 'package:app_educativa/features/progreso/domain/progreso_modulo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'datos_actividades.dart';

/// Contenido real que se sube a Firebase Storage.
const _rutaSociales =
    '../../backend/contenidos/modulos/cs-grado-1/actividades.json';

ProgresoModulo _progresoCon(Map<String, int> puntajes) {
  return ProgresoModulo(
    moduloId: 'cs-grado-1',
    porcentaje: 0,
    ultimaActualizacion: null,
    lecturas: const [],
    actividades: [
      for (final entrada in puntajes.entries)
        ProgresoActividad(
          actividadId: entrada.key,
          completada: true,
          puntaje: entrada.value,
          intentos: 1,
          ultimaActualizacion: DateTime(2026, 10, 25),
        ),
    ],
  );
}

void main() {
  group('Contenido de Ciencias Sociales 1° (actividades.json)', () {
    late PlanActividades sociales;

    setUpAll(() async {
      sociales = await const ActividadesLocalDataSource()
          .leerArchivo(_rutaSociales);
    });

    test('tiene 5 niveles en orden, de lo cercano a lo lejano', () {
      expect(sociales.niveles.map((nivel) => nivel.numero), [1, 2, 3, 4, 5]);
      expect(sociales.niveles.map((nivel) => nivel.titulo), [
        'Yo soy único',
        'Mi familia',
        'Mis vecinos y sus oficios',
        'Mi región y la naturaleza',
        'Colombia diversa',
      ]);
    });

    test('cada nivel tiene 3 juegos y máximo 1 de pregunta y respuesta', () {
      for (final nivel in sociales.niveles) {
        expect(nivel.actividades, hasLength(3), reason: nivel.titulo);
        expect(
          nivel.actividades.whereType<ActividadElige>().length,
          lessThanOrEqualTo(1),
          reason: nivel.titulo,
        );
      }
    });

    test('usa los juegos interactivos: memoria, arrastra, atrapa y ordena', () {
      expect(
        sociales.actividades.map((actividad) => actividad.tipo).toSet(),
        containsAll([
          TipoActividad.memoria,
          TipoActividad.arrastra,
          TipoActividad.atrapa,
          TipoActividad.ordena,
        ]),
      );
    });

    test('las preguntas tienen máximo 3 opciones (fácil para niños)', () {
      for (final actividad in sociales.actividades.whereType<ActividadElige>()) {
        for (final pregunta in actividad.preguntas) {
          expect(pregunta.opciones.length, inInclusiveRange(2, 3),
              reason: pregunta.enunciado);
        }
      }
    });
  });

  group('Contenido de Lenguaje 3° (Períodos 1 y 2)', () {
    for (final modulo in ['lg-grado-3-01', 'lg-grado-3-02']) {
      test('$modulo: 5 niveles de 3 juegos, máximo 1 de pregunta y respuesta',
          () async {
        final plan = await const ActividadesLocalDataSource().leerArchivo(
          '../../backend/contenidos/modulos/$modulo/actividades.json',
        );

        expect(plan.niveles.map((nivel) => nivel.numero), [1, 2, 3, 4, 5]);
        for (final nivel in plan.niveles) {
          expect(nivel.actividades, hasLength(3), reason: nivel.titulo);
          expect(
            nivel.actividades.whereType<ActividadElige>().length,
            lessThanOrEqualTo(1),
            reason: nivel.titulo,
          );
        }
        // Usa los juegos nuevos para tercer grado.
        expect(
          plan.actividades.map((actividad) => actividad.tipo).toSet(),
          containsAll([TipoActividad.completa, TipoActividad.sopa]),
        );

        // Todas sus sopas de letras se pueden armar.
        for (final sopa in plan.actividades.whereType<ActividadSopa>()) {
          final cuadricula = CuadriculaSopa.generar(
            sopa.palabras.map((palabra) => palabra.texto).toList(),
            sopa.tamano,
            Random(3),
          );
          expect(cuadricula.ubicaciones, hasLength(sopa.palabras.length));
        }
      });
    }
  });

  group('Pistas (fragmentos de la cartilla)', () {
    const paginasPorModulo = {
      'cs-grado-1': 22,
      'lg-grado-3-01': 48,
      'lg-grado-3-02': 54,
    };

    for (final MapEntry(key: modulo, value: paginas)
        in paginasPorModulo.entries) {
      test('$modulo: cada juego tiene pista y su página existe en el PDF',
          () async {
        final plan = await const ActividadesLocalDataSource().leerArchivo(
          '../../backend/contenidos/modulos/$modulo/actividades.json',
        );

        for (final actividad in plan.actividades) {
          final pista = actividad.pista;
          expect(pista, isNotNull, reason: actividad.id);
          if (pista!.pagina != null) {
            expect(pista.pagina, inInclusiveRange(1, paginas));
          }
        }
      });
    }

    test('lee la pista de la actividad y la de cada pregunta', () {
      final plan = const ActividadesLocalDataSource().interpretar(
        jsonEncode({
          'niveles': [
            {
              'id': 'n1',
              'numero': 1,
              'titulo': 'N',
              'emoji': '⭐',
              'objetivo': 'O',
              'actividades': [
                {
                  'id': 'a1',
                  'tipo': 'elige',
                  'titulo': 'Elige',
                  'instruccion': 'Elige',
                  'pista': {'texto': 'Guía 1', 'pagina': 9},
                  'preguntas': [
                    {
                      'enunciado': '¿?',
                      'opciones': [
                        {'emoji': 'a', 'texto': 'A'},
                        {'emoji': 'b', 'texto': 'B'},
                      ],
                      'correcta': 0,
                      'pista': {'texto': 'Fragmento'},
                    },
                  ],
                },
              ],
            },
          ],
        }),
      );

      final actividad = plan.actividades.single as ActividadElige;
      expect(actividad.pista!.texto, 'Guía 1');
      expect(actividad.pista!.pagina, 9);
      expect(actividad.preguntas.single.pista!.texto, 'Fragmento');
      expect(actividad.preguntas.single.pista!.pagina, isNull);
    });
  });

  group('Sopa de letras', () {
    test('esconde cada palabra en su lugar (sin tildes y en mayúsculas)', () {
      for (var semilla = 0; semilla < 40; semilla++) {
        final cuadricula = CuadriculaSopa.generar(
          ['Astronauta', 'Órbita', 'Luna', 'Nave', 'Cohete'],
          10,
          Random(semilla),
        );

        expect(cuadricula.tamano, greaterThanOrEqualTo(10));
        for (final ubicacion in cuadricula.ubicaciones) {
          final leida = ubicacion.celdas
              .map((celda) => cuadricula.letra(celda.$1, celda.$2))
              .join();
          expect(leida, ubicacion.palabra);
          expect(
            cuadricula.buscar(ubicacion.fin, ubicacion.inicio),
            same(ubicacion),
            reason: 'también vale seleccionarla al revés',
          );
        }
        expect(
          cuadricula.ubicaciones.map((u) => u.palabra),
          containsAll(['ASTRONAUTA', 'ORBITA', 'LUNA', 'NAVE', 'COHETE']),
        );
      }
    });

    test('rechaza palabras que no caben', () {
      expect(
        () => const ActividadesLocalDataSource().interpretar(
          jsonEncode({
            'niveles': [
              {
                'id': 'n1',
                'numero': 1,
                'titulo': 'N',
                'emoji': '⭐',
                'objetivo': 'O',
                'actividades': [
                  {
                    'id': 's1',
                    'tipo': 'sopa',
                    'titulo': 'Sopa',
                    'instruccion': 'Busca',
                    'tamano': 6,
                    'palabras': [
                      {'emoji': '👨‍🚀', 'texto': 'Astronauta'},
                    ],
                  },
                ],
              },
            ],
          }),
        ),
        throwsA(isA<ActividadesInvalidasException>()),
      );
    });
  });

  group('Lectura y validación del JSON', () {
    const datos = ActividadesLocalDataSource();

    String planCon(Map<String, Object?> actividad) {
      return jsonEncode({
        'niveles': [
          {
            'id': 'n1',
            'numero': 1,
            'titulo': 'Nivel',
            'emoji': '⭐',
            'objetivo': 'Objetivo',
            'actividades': [actividad],
          },
        ],
      });
    }

    test('lee una actividad válida', () {
      final plan = datos.interpretar(
        planCon({
          'id': 'a1',
          'tipo': 'ordena',
          'titulo': 'Ordena',
          'instruccion': 'Toca en orden',
          'pasos': [
            {'emoji': '1️⃣', 'texto': 'Uno'},
            {'emoji': '2️⃣', 'texto': 'Dos'},
          ],
        }),
      );

      final actividad = plan.actividades.single as ActividadOrdena;
      expect(actividad.pasos.map((paso) => paso.texto), ['Uno', 'Dos']);
    });

    test('rechaza una respuesta correcta que no existe', () {
      expect(
        () => datos.interpretar(
          planCon({
            'id': 'a1',
            'tipo': 'elige',
            'titulo': 'Elige',
            'instruccion': 'Elige',
            'preguntas': [
              {
                'enunciado': '¿?',
                'opciones': [
                  {'emoji': 'a', 'texto': 'A'},
                  {'emoji': 'b', 'texto': 'B'},
                ],
                'correcta': 5,
              },
            ],
          }),
        ),
        throwsA(isA<ActividadesInvalidasException>()),
      );
    });

    test('rechaza una tarjeta con un grupo que no existe', () {
      expect(
        () => datos.interpretar(
          planCon({
            'id': 'a1',
            'tipo': 'clasifica',
            'titulo': 'Clasifica',
            'instruccion': 'Clasifica',
            'grupos': [
              {'id': 'si', 'emoji': '✅', 'texto': 'Sí'},
              {'id': 'no', 'emoji': '❌', 'texto': 'No'},
            ],
            'tarjetas': [
              {'emoji': '🌱', 'texto': 'Planta', 'grupo': 'tal-vez'},
            ],
          }),
        ),
        throwsA(isA<ActividadesInvalidasException>()),
      );
    });

    test('lee un juego de globos y cuenta solo los correctos', () {
      final plan = datos.interpretar(
        planCon({
          'id': 'a1',
          'tipo': 'atrapa',
          'titulo': 'Globos',
          'instruccion': 'Revienta',
          'objetivo': {'emoji': '🌳', 'texto': 'naturaleza'},
          'elementos': [
            {'emoji': '⛰️', 'texto': 'Montaña', 'correcto': true},
            {'emoji': '🌊', 'texto': 'Mar', 'correcto': true},
            {'emoji': '🏠', 'texto': 'Casa', 'correcto': false},
          ],
        }),
      );

      expect(plan.actividades.single.totalAciertos, 2);
    });

    test('rechaza un juego de globos sin globos incorrectos', () {
      expect(
        () => datos.interpretar(
          planCon({
            'id': 'a1',
            'tipo': 'atrapa',
            'titulo': 'Globos',
            'instruccion': 'Revienta',
            'objetivo': {'emoji': '🌳', 'texto': 'naturaleza'},
            'elementos': [
              {'emoji': '⛰️', 'texto': 'Montaña', 'correcto': true},
            ],
          }),
        ),
        throwsA(isA<ActividadesInvalidasException>()),
      );
    });

    test('rechaza una oración para completar sin espacio en blanco', () {
      expect(
        () => datos.interpretar(
          planCon({
            'id': 'a1',
            'tipo': 'completa',
            'titulo': 'Completa',
            'instruccion': 'Completa',
            'oraciones': [
              {
                'emoji': '🏫',
                'texto': 'La escuela era pequeña.',
                'opciones': ['pequeña', 'grande'],
                'correcta': 0,
              },
            ],
          }),
        ),
        throwsA(isA<ActividadesInvalidasException>()),
      );
    });

    test('rechaza un tipo de juego desconocido', () {
      expect(
        () => datos.interpretar(
          planCon({
            'id': 'a1',
            'tipo': 'carreras',
            'titulo': 'X',
            'instruccion': 'X',
          }),
        ),
        throwsA(isA<ActividadesInvalidasException>()),
      );
    });

    test('rechaza un JSON dañado', () {
      expect(
        () => datos.interpretar('{"niveles": ['),
        throwsA(isA<ActividadesInvalidasException>()),
      );
    });

    test('HU07 CA2: lee los juegos solo desde el dispositivo', () async {
      final carpeta = await Directory.systemTemp.createTemp('actividades_');
      addTearDown(() => carpeta.delete(recursive: true));
      final archivo = File(p.join(carpeta.path, 'actividades.json'));
      await archivo.writeAsString(await File(_rutaSociales).readAsString());

      final recursos = [
        RecursoLocal(
          titulo: 'Fichas',
          tipo: 'pdf',
          ruta: p.join(carpeta.path, 'fichas.pdf'),
        ),
        RecursoLocal(
          titulo: 'Juegos',
          tipo: ActividadesLocalDataSource.tipoRecurso,
          ruta: archivo.path,
        ),
      ];

      final leido = await datos.leer(recursos);
      expect(leido!.niveles, hasLength(5));
    });

    test('un módulo sin juegos devuelve null', () async {
      expect(
        await datos.leer(const [
          RecursoLocal(titulo: 'Fichas', tipo: 'pdf', ruta: '/x/fichas.pdf'),
        ]),
        isNull,
      );
    });
  });

  group('Puntaje y estrellas', () {
    test('sin errores son 100 puntos y 3 estrellas', () {
      final puntaje = calcularPuntaje(aciertos: 4, errores: 0);
      expect(puntaje, 100);
      expect(estrellasPorPuntaje(puntaje), 3);
    });

    test('los errores bajan el puntaje pero siempre se gana al menos 1 estrella',
        () {
      expect(calcularPuntaje(aciertos: 4, errores: 2), 67);
      expect(estrellasPorPuntaje(67), 2);
      expect(estrellasPorPuntaje(calcularPuntaje(aciertos: 4, errores: 20)), 1);
    });
  });

  group('Ruta de aprendizaje por niveles', () {
    test('al empezar solo está abierto el primer juego del nivel 1', () {
      final ruta = RutaAprendizaje.calcular(
        plan,
        const ProgresoModulo.vacio('cs-grado-1'),
      );

      expect(ruta.pasos.map((paso) => paso.estado), [
        EstadoActividad.disponible,
        EstadoActividad.bloqueada,
        EstadoActividad.bloqueada,
        EstadoActividad.bloqueada,
      ]);
      expect(ruta.niveles[0].estaDesbloqueado, isTrue);
      expect(ruta.niveles[1].estaDesbloqueado, isFalse);
      expect(ruta.siguiente!.actividad.id, elige.id);
    });

    test('terminar un juego abre el siguiente del mismo nivel', () {
      final ruta = RutaAprendizaje.calcular(
        plan,
        _progresoCon({elige.id: 100}),
      );

      expect(ruta.pasos[0].estado, EstadoActividad.completada);
      expect(ruta.pasos[0].estrellas, 3);
      expect(ruta.pasos[1].estado, EstadoActividad.disponible);
      expect(ruta.niveles[1].estaDesbloqueado, isFalse);
    });

    test('el nivel 2 se abre solo al terminar todo el nivel 1', () {
      final ruta = RutaAprendizaje.calcular(
        plan,
        _progresoCon({elige.id: 100, parejas.id: 50}),
      );

      expect(ruta.niveles[0].estaCompletado, isTrue);
      expect(ruta.niveles[0].estrellas, 3 + 1);
      expect(ruta.niveles[1].estaDesbloqueado, isTrue);
      expect(ruta.siguiente!.actividad.id, clasifica.id);
      expect(ruta.pasos.last.estado, EstadoActividad.bloqueada);
    });

    test('al terminar todo no queda siguiente juego', () {
      final ruta = RutaAprendizaje.calcular(
        plan,
        _progresoCon({
          elige.id: 100,
          parejas.id: 100,
          clasifica.id: 100,
          ordena.id: 100,
        }),
      );

      expect(ruta.siguiente, isNull);
      expect(ruta.actividadesCompletadas, 4);
      expect(ruta.despuesDe(parejas.id)!.actividad.id, clasifica.id);
      expect(ruta.despuesDe(ordena.id), isNull);
    });
  });
}
