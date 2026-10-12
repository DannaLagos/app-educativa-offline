import 'package:app_educativa/features/modulos/data/modulo_repository.dart';
import 'package:app_educativa/features/modulos/domain/estado_descarga.dart';
import 'package:app_educativa/features/modulos/domain/modulo.dart';
import 'package:app_educativa/features/modulos/presentation/controllers/modulos_controller.dart';
import 'package:app_educativa/features/modulos/presentation/controllers/modulos_scope.dart';
import 'package:app_educativa/features/modulos/presentation/screens/detalle_modulo_screen.dart';
import 'package:app_educativa/features/modulos/presentation/screens/modulos_screen.dart';
import 'package:app_educativa/features/modulos/presentation/widgets/estado_descarga_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/datos_prueba.dart';

class MockRepositorio extends Mock implements ModuloRepository {}

void main() {
  late MockRepositorio repositorio;
  late ModulosController controller;

  setUp(() {
    repositorio = MockRepositorio();
    controller = ModulosController(repositorio: repositorio);
  });

  void catalogo(List<Modulo> modulos, {bool desdeCache = false}) {
    when(() => repositorio.obtenerCatalogo()).thenAnswer(
      (_) async => ResultadoCatalogo(
        modulos: modulos,
        desdeCache: desdeCache,
      ),
    );
  }

  Widget app(Widget home) {
    return ModulosScope(
      controller: controller,
      child: MaterialApp(home: home),
    );
  }

  group('EstadoDescargaChip', () {
    Future<void> mostrar(
      WidgetTester tester,
      EstadoDescarga estado, {
      double? progreso,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EstadoDescargaChip(
              estado: estado,
              progreso: progreso,
              grande: true,
            ),
          ),
        ),
      );
    }

    testWidgets('no descargado', (tester) async {
      await mostrar(tester, EstadoDescarga.noDescargado);
      expect(find.text('No descargado'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('descargando muestra el porcentaje y la barra',
        (tester) async {
      await mostrar(tester, EstadoDescarga.descargando, progreso: 0.45);
      expect(find.text('Descargando 45 %'), findsOneWidget);
      final barra = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(barra.value, 0.45);
    });

    testWidgets('descargado', (tester) async {
      await mostrar(tester, EstadoDescarga.descargado);
      expect(find.text('Descargado'), findsOneWidget);
    });

    testWidgets('error', (tester) async {
      await mostrar(tester, EstadoDescarga.error);
      expect(find.text('Error en la descarga'), findsOneWidget);
    });
  });

  testWidgets('la lista agrupa los módulos por área y grado', (tester) async {
    catalogo([
      moduloDePrueba(
        id: 'cs-grado-1',
        nombre: 'Ciencias Sociales',
        area: 'Ciencias Sociales',
        grado: 1,
      ),
      moduloDePrueba(id: 'lg-1', nombre: 'Lenguaje - Módulo 1'),
      moduloDePrueba(id: 'lg-2', nombre: 'Lenguaje - Módulo 2'),
    ]);

    await tester.pumpWidget(app(const ModulosScreen()));
    await tester.pumpAndSettle();

    Finder encabezado(String texto) => find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is Semantics && (w.properties.header ?? false),
          ),
          matching: find.text(texto),
        );

    // Un encabezado por grupo; además cada tarjeta repite área y grado.
    expect(encabezado('Ciencias Sociales · Grado 1'), findsOneWidget);
    expect(encabezado('Lenguaje · Grado 3'), findsOneWidget);
    expect(find.text('Lenguaje · Grado 3'), findsNWidgets(3));
    expect(find.text('Lenguaje - Módulo 1'), findsOneWidget);
    expect(find.text('Lenguaje - Módulo 2'), findsOneWidget);
    expect(find.text('Sin internet. Estás viendo los módulos guardados.'),
        findsNothing);
  });

  testWidgets('sin conexión avisa que los módulos vienen de la caché',
      (tester) async {
    catalogo([moduloDePrueba()], desdeCache: true);

    await tester.pumpWidget(app(const ModulosScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Sin internet. Estás viendo los módulos guardados.'),
        findsOneWidget);
    expect(find.text('Lenguaje - Módulo 1'), findsOneWidget);
  });

  testWidgets('el detalle muestra la información, contenidos y estado',
      (tester) async {
    catalogo([
      moduloDePrueba(
        estado: EstadoDescarga.descargado,
        fechaDescarga: DateTime(2026, 10, 12),
      ),
    ]);
    await controller.cargarCatalogo();

    await tester.pumpWidget(
      app(const DetalleModuloScreen(moduloId: 'lg-grado-3-01')),
    );

    expect(find.text('Lenguaje'), findsOneWidget);
    expect(find.text('Grado 3'), findsOneWidget);
    expect(find.text('El cuento'), findsOneWidget);
    expect(find.text('Los personajes'), findsOneWidget);
    expect(find.text('Descargado'), findsOneWidget);
    expect(find.text('Descargado el 12/10/2026'), findsOneWidget);
  });
}
