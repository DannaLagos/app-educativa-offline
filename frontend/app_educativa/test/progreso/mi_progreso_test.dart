import 'package:app_educativa/features/actividades/domain/ruta_aprendizaje.dart';
import 'package:app_educativa/features/modulos/data/descarga_service.dart';
import 'package:app_educativa/features/modulos/data/modulo_repository.dart';
import 'package:app_educativa/features/modulos/domain/estado_descarga.dart';
import 'package:app_educativa/features/modulos/domain/resultado_catalogo.dart';
import 'package:app_educativa/features/modulos/presentation/controllers/modulos_controller.dart';
import 'package:app_educativa/features/modulos/presentation/controllers/modulos_scope.dart';
import 'package:app_educativa/features/progreso/data/progreso_repository.dart';
import 'package:app_educativa/features/progreso/domain/progreso_modulo.dart';
import 'package:app_educativa/features/progreso/domain/resumen_modulo.dart';
import 'package:app_educativa/features/progreso/presentation/progreso_controller.dart';
import 'package:app_educativa/features/progreso/presentation/progreso_scope.dart';
import 'package:app_educativa/features/progreso/presentation/screens/detalle_progreso_screen.dart';
import 'package:app_educativa/features/progreso/presentation/screens/mi_progreso_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../actividades/datos_actividades.dart';
import '../helpers/datos_prueba.dart';

class MockModuloRepository extends Mock implements ModuloRepository {}

class MockDescargaService extends Mock implements DescargaService {}

class MockProgresoRepository extends Mock implements ProgresoRepository {}

ProgresoModulo _progreso(
  String moduloId, {
  Map<String, int> juegos = const {},
  int? pagina,
}) {
  final fecha = DateTime(2026, 10, 25, 10);

  return ProgresoModulo(
    moduloId: moduloId,
    porcentaje: 0,
    ultimaActualizacion: fecha,
    lecturas: [
      if (pagina != null)
        ProgresoLectura(
          recurso: 'cartilla.pdf',
          ultimaPagina: pagina,
          paginaMaxima: pagina,
          totalPaginas: 20,
          ultimaActualizacion: fecha,
        ),
    ],
    actividades: [
      for (final MapEntry(key: id, value: puntaje) in juegos.entries)
        ProgresoActividad(
          actividadId: id,
          completada: true,
          puntaje: puntaje,
          intentos: 1,
          ultimaActualizacion: fecha,
        ),
    ],
  );
}

void main() {
  final sociales = moduloDePrueba(
    id: 'cs-grado-1',
    nombre: 'Ciencias Sociales',
    area: 'Ciencias Sociales',
    grado: 1,
    estado: EstadoDescarga.descargado,
    rutaLocal: '/datos/modulos/cs-grado-1',
  );
  final lenguaje = moduloDePrueba(
    id: 'lg-grado-3-01',
    nombre: 'Lenguaje - Período 1',
  );

  group('ResumenModulo', () {
    test('CA1 y CA2: cuenta terminados, pendientes y estrellas', () {
      final resumen = ResumenModulo(
        modulo: sociales,
        progreso: _progreso(
          'cs-grado-1',
          juegos: {elige.id: 100, parejas.id: 50},
          pagina: 5,
        ),
        plan: plan,
      );

      expect(resumen.estaIniciado, isTrue);
      expect(resumen.juegosTerminados, 2);
      expect(resumen.juegosTotales, 4);
      expect(resumen.juegosPendientes, 2);
      expect(resumen.estrellas, 3 + 1);
      expect(resumen.avanceJuegos, 0.5);
      expect(resumen.lectura!.ultimaPagina, 5);
      expect(resumen.estaTerminado, isFalse);
      expect(resumen.ruta!.pasos.map((paso) => paso.estado), [
        EstadoActividad.completada,
        EstadoActividad.completada,
        EstadoActividad.disponible,
        EstadoActividad.bloqueada,
      ]);
    });

    test('sin los juegos descargados muestra lo que ya terminó', () {
      final resumen = ResumenModulo(
        modulo: sociales,
        progreso: _progreso('cs-grado-1', juegos: {elige.id: 90}),
        plan: null,
      );

      expect(resumen.juegosTerminados, 1);
      expect(resumen.juegosTotales, isNull);
      expect(resumen.avanceJuegos, isNull);
      expect(resumen.estrellas, 3);
    });

    test('con todos los juegos terminados el módulo queda terminado', () {
      final resumen = ResumenModulo(
        modulo: sociales,
        progreso: _progreso('cs-grado-1', juegos: {
          for (final actividad in plan.actividades) actividad.id: 100,
        }),
        plan: plan,
      );

      expect(resumen.estaTerminado, isTrue);
      expect(resumen.juegosPendientes, 0);
    });
  });

  group('Pantallas de Mi progreso', () {
    late MockModuloRepository modulos;
    late MockProgresoRepository progresos;
    late ModulosController modulosController;
    late ProgresoController progresoController;

    setUp(() {
      modulos = MockModuloRepository();
      progresos = MockProgresoRepository();
      modulosController = ModulosController(
        repositorio: modulos,
        descargaService: MockDescargaService(),
      );
      progresoController = ProgresoController(repositorio: progresos);

      // CA3: los módulos vienen de la copia local (sin internet).
      when(() => modulos.obtenerCatalogo()).thenAnswer(
        (_) async => ResultadoCatalogo(
          modulos: [sociales, lenguaje],
          vieneDeCache: true,
        ),
      );
      when(() => modulos.obtenerDescargados())
          .thenAnswer((_) async => [sociales]);
      when(() => progresos.obtenerProgresoModulo('cs-grado-1')).thenAnswer(
        (_) async => _progreso(
          'cs-grado-1',
          juegos: {elige.id: 100, parejas.id: 50},
          pagina: 5,
        ),
      );
      when(() => progresos.obtenerProgresoModulo('lg-grado-3-01')).thenAnswer(
        (_) async => const ProgresoModulo.vacio('lg-grado-3-01'),
      );
    });

    Future<void> mostrar(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ModulosScope(
          controller: modulosController,
          child: ProgresoScope(
            controller: progresoController,
            child: MaterialApp(
              home: MiProgresoScreen(
                cargarPlan: (_, modulo) async =>
                    modulo.id == 'cs-grado-1' ? plan : null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('CA1 y CA3: lista los módulos con su avance, sin internet',
        (tester) async {
      await mostrar(tester);

      expect(find.text('Módulos que empezaste'), findsOneWidget);
      expect(find.text('🎮 2 de 4 juegos · ⭐ 4'), findsOneWidget);
      expect(find.text('📖 Página 5 de 20'), findsOneWidget);
      expect(find.text('Sin empezar'), findsNWidgets(2));
      expect(
        find.textContaining('Puedes verlo sin internet'),
        findsOneWidget,
      );
    });

    testWidgets(
        'CA2: el detalle diferencia juegos terminados, pendientes y '
        'bloqueados', (tester) async {
      await mostrar(tester);

      await tester.tap(find.byKey(const ValueKey('resumen-cs-grado-1')));
      await tester.pumpAndSettle();

      expect(find.byType(DetalleProgresoScreen), findsOneWidget);
      expect(find.text('🎮 Juegos: 2 de 4'), findsOneWidget);
      expect(find.text('Nivel 1: Yo soy único'), findsOneWidget);
      expect(find.text('2 de 2'), findsOneWidget);

      // Cada estado tiene su símbolo, texto y color.
      expect(find.text('Terminado'), findsNWidgets(2));
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('Bloqueado'), findsOneWidget);
      expect(find.text('✅ Terminado'), findsOneWidget, reason: 'leyenda');

      final terminado = tester.widget<Container>(
        find.byKey(ValueKey('progreso-${elige.id}')),
      );
      final pendiente = tester.widget<Container>(
        find.byKey(ValueKey('progreso-${clasifica.id}')),
      );
      expect(
        (terminado.decoration! as BoxDecoration).color,
        isNot((pendiente.decoration! as BoxDecoration).color),
      );
    });
  });
}
