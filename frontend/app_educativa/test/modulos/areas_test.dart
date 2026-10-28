import 'package:app_educativa/features/modulos/data/descarga_service.dart';
import 'package:app_educativa/features/modulos/data/modulo_repository.dart';
import 'package:app_educativa/features/modulos/domain/area_resumen.dart';
import 'package:app_educativa/features/modulos/domain/estado_descarga.dart';
import 'package:app_educativa/features/modulos/domain/modulo.dart';
import 'package:app_educativa/features/modulos/domain/resultado_catalogo.dart';
import 'package:app_educativa/features/modulos/presentation/controllers/modulos_controller.dart';
import 'package:app_educativa/features/modulos/presentation/controllers/modulos_scope.dart';
import 'package:app_educativa/features/modulos/presentation/screens/areas_screen.dart';
import 'package:app_educativa/features/modulos/presentation/screens/modulos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/datos_prueba.dart';

class MockRepositorio extends Mock implements ModuloRepository {}

class MockDescargaService extends Mock implements DescargaService {}

void main() {
  final sociales = moduloDePrueba(
    id: 'cs-grado-1',
    nombre: 'Ciencias Sociales',
    area: 'Ciencias Sociales',
    grado: 1,
  );
  final lenguaje1 = moduloDePrueba(id: 'lg-1', nombre: 'Lenguaje - Período 1');
  final lenguaje2 = moduloDePrueba(id: 'lg-2', nombre: 'Lenguaje - Período 2');

  group('AreaResumen', () {
    test('agrupa por área con sus grados y cantidad de módulos', () {
      final areas = AreaResumen.agrupar([
        lenguaje1,
        sociales,
        lenguaje2,
        moduloDePrueba(id: 'lg-5', grado: 5),
      ]);

      expect(areas.map((a) => a.area), ['Ciencias Sociales', 'Lenguaje']);
      expect(areas[0].descripcion, 'Grado 1 • 1 módulo disponible');
      expect(areas[1].grados, [3, 5]);
      expect(areas[1].descripcion, 'Grados 3 y 5 • 3 módulos disponibles');
    });

    test('con tres grados los separa con comas', () {
      final area = AreaResumen.agrupar([
        moduloDePrueba(id: 'a', grado: 1),
        moduloDePrueba(id: 'b', grado: 2),
        moduloDePrueba(id: 'c', grado: 3),
      ]).single;

      expect(area.descripcion, 'Grados 1, 2 y 3 • 3 módulos disponibles');
    });
  });

  group('pantallas de áreas', () {
    late MockRepositorio repositorio;
    late MockDescargaService descargaService;
    late ModulosController controller;

    setUpAll(() => registerFallbackValue(moduloDePrueba()));

    setUp(() {
      repositorio = MockRepositorio();
      descargaService = MockDescargaService();
      controller = ModulosController(
        repositorio: repositorio,
        descargaService: descargaService,
      );
      when(() => repositorio.obtenerCatalogo()).thenAnswer(
        (_) async => ResultadoCatalogo(
          modulos: [sociales, lenguaje1, lenguaje2],
          vieneDeCache: false,
        ),
      );
    });

    Widget app(Widget home) => ModulosScope(
          controller: controller,
          child: MaterialApp(home: home),
        );

    testWidgets('áreas lleva a la lista de módulos solo de esa área',
        (tester) async {
      await tester.pumpWidget(app(const AreasScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Ciencias Sociales'), findsOneWidget);
      expect(find.text('Grado 3 • 2 módulos disponibles'), findsOneWidget);

      await tester.tap(find.text('Lenguaje'));
      await tester.pumpAndSettle();

      expect(find.byType(ModulosScreen), findsOneWidget);
      expect(find.text('Lenguaje - Período 1'), findsOneWidget);
      expect(find.text('Lenguaje - Período 2'), findsOneWidget);
      expect(find.text('Ciencias Sociales · Grado 1'), findsNothing);
    });

    testWidgets('se puede descargar desde la tarjeta de la lista',
        (tester) async {
      when(
        () => descargaService.descargar(
          any(),
          onProgreso: any(named: 'onProgreso'),
        ),
      ).thenAnswer((_) async {});
      when(() => repositorio.obtenerModulo('cs-grado-1')).thenAnswer(
        (_) async => moduloDePrueba(
          id: 'cs-grado-1',
          nombre: 'Ciencias Sociales',
          area: 'Ciencias Sociales',
          grado: 1,
          estado: EstadoDescarga.descargado,
        ),
      );

      await tester.pumpWidget(
        app(const ModulosScreen(area: 'Ciencias Sociales')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Descargar Ciencias Sociales'));
      await tester.pumpAndSettle();

      verify(
        () => descargaService.descargar(
          any(that: isA<Modulo>().having((m) => m.id, 'id', 'cs-grado-1')),
          onProgreso: any(named: 'onProgreso'),
        ),
      ).called(1);
      expect(find.text('Descargado'), findsOneWidget);
      expect(find.byTooltip('Descargar Ciencias Sociales'), findsNothing);
      expect(
        find.text('"Ciencias Sociales" ya está disponible sin internet.'),
        findsOneWidget,
      );
    });
  });
}
