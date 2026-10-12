import 'dart:async';

import 'package:app_educativa/features/modulos/data/descarga_service.dart';
import 'package:app_educativa/features/modulos/data/modulo_repository.dart';
import 'package:app_educativa/features/modulos/domain/estado_descarga.dart';
import 'package:app_educativa/features/modulos/domain/modulo.dart';
import 'package:app_educativa/features/modulos/domain/recurso_local.dart';
import 'package:app_educativa/features/modulos/presentation/controllers/modulos_controller.dart';
import 'package:app_educativa/features/modulos/presentation/controllers/modulos_scope.dart';
import 'package:app_educativa/features/modulos/presentation/screens/detalle_modulo_screen.dart';
import 'package:app_educativa/features/modulos/presentation/screens/lector_modulo_screen.dart';
import 'package:app_educativa/features/modulos/presentation/screens/mis_descargas_screen.dart';
import 'package:app_educativa/features/modulos/presentation/widgets/confirmar_eliminar_dialog.dart';
import 'package:app_educativa/features/modulos/presentation/screens/modulos_screen.dart';
import 'package:app_educativa/features/modulos/presentation/widgets/estado_descarga_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/datos_prueba.dart';

class MockRepositorio extends Mock implements ModuloRepository {}

class MockDescargaService extends Mock implements DescargaService {}

void main() {
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

  group('descarga desde el detalle', () {
    const id = 'lg-grado-3-01';

    Future<void> abrirDetalle(WidgetTester tester, Modulo modulo) async {
      catalogo([modulo]);
      await controller.cargarCatalogo();
      await tester.pumpWidget(
        app(const DetalleModuloScreen(moduloId: id)),
      );
    }

    testWidgets('muestra el progreso y termina en "Descargado"',
        (tester) async {
      final terminar = Completer<void>();
      late void Function(double) reportar;

      when(
        () => descargaService.descargar(
          any(),
          onProgreso: any(named: 'onProgreso'),
        ),
      ).thenAnswer((invocacion) {
        reportar = invocacion.namedArguments[#onProgreso]
            as void Function(double);
        return terminar.future;
      });

      await abrirDetalle(tester, moduloDePrueba());
      expect(find.text('No descargado'), findsOneWidget);

      await tester.tap(find.text('Descargar'));
      await tester.pump();
      reportar(0.6);
      await tester.pump();

      expect(find.text('Descargando 60 %'), findsOneWidget);
      expect(find.text('Descargar'), findsNothing);

      when(() => repositorio.obtenerModulo(id)).thenAnswer(
        (_) async => moduloDePrueba(estado: EstadoDescarga.descargado),
      );
      terminar.complete();
      await tester.pumpAndSettle();

      expect(find.text('Descargado'), findsOneWidget);
      expect(find.text('Disponible sin conexión.'), findsOneWidget);
      expect(
        find.text('¡Listo! Ya puedes usar este módulo sin internet.'),
        findsOneWidget,
      );
    });

    testWidgets('si falla muestra un mensaje claro y permite reintentar',
        (tester) async {
      when(
        () => descargaService.descargar(
          any(),
          onProgreso: any(named: 'onProgreso'),
        ),
      ).thenThrow(
        const DescargaException(MotivoFalloDescarga.sinConexion),
      );
      when(() => repositorio.obtenerModulo(id)).thenAnswer(
        (_) async => moduloDePrueba(),
      );

      await abrirDetalle(tester, moduloDePrueba());
      await tester.tap(find.text('Descargar'));
      await tester.pumpAndSettle();

      expect(find.text('Error en la descarga'), findsOneWidget);
      expect(
        find.text(MotivoFalloDescarga.sinConexion.mensaje),
        findsOneWidget,
      );

      // Al reintentar con conexión, la descarga se completa.
      when(
        () => descargaService.descargar(
          any(),
          onProgreso: any(named: 'onProgreso'),
        ),
      ).thenAnswer((_) async {});
      when(() => repositorio.obtenerModulo(id)).thenAnswer(
        (_) async => moduloDePrueba(estado: EstadoDescarga.descargado),
      );

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Descargado'), findsOneWidget);
      verify(
        () => descargaService.descargar(
          any(),
          onProgreso: any(named: 'onProgreso'),
        ),
      ).called(2);
    });

    testWidgets('un error guardado de una sesión anterior permite reintentar',
        (tester) async {
      await abrirDetalle(
        tester,
        moduloDePrueba(estado: EstadoDescarga.error),
      );

      expect(
        find.text('La descarga anterior no terminó. Vuelve a intentarlo.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('acceso offline (HU04)', () {
    final descargado = moduloDePrueba(
      estado: EstadoDescarga.descargado,
      rutaLocal: '/datos/modulos/lg-grado-3-01',
    );

    const leccion1 = RecursoLocal(
      titulo: 'Lección 1',
      tipo: 'pdf',
      ruta: '/datos/modulos/lg-grado-3-01/l1.pdf',
    );
    const leccion2 = RecursoLocal(
      titulo: 'Lección 2',
      tipo: 'pdf',
      ruta: '/datos/modulos/lg-grado-3-01/l2.pdf',
    );

    Widget visorFalso(RecursoLocal recurso) => Text('VISOR ${recurso.ruta}');

    testWidgets('el detalle de un módulo descargado permite abrirlo',
        (tester) async {
      catalogo([descargado]);
      await controller.cargarCatalogo();

      await tester.pumpWidget(
        app(const DetalleModuloScreen(moduloId: 'lg-grado-3-01')),
      );

      expect(find.text('Abrir módulo'), findsOneWidget);
      expect(find.text('Descargar'), findsNothing);
    });

    testWidgets('con un solo documento lo abre directamente', (tester) async {
      when(() => repositorio.obtenerRecursosLocales(any()))
          .thenAnswer((_) async => [leccion1]);

      await tester.pumpWidget(
        app(
          LectorModuloScreen(
            modulo: descargado,
            construirVisor: visorFalso,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VISOR ${leccion1.ruta}'), findsOneWidget);
    });

    testWidgets('con varios documentos deja elegir cuál abrir',
        (tester) async {
      when(() => repositorio.obtenerRecursosLocales(any()))
          .thenAnswer((_) async => [leccion1, leccion2]);

      await tester.pumpWidget(
        app(
          LectorModuloScreen(
            modulo: descargado,
            construirVisor: visorFalso,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lección 2'));
      await tester.pumpAndSettle();

      expect(find.text('VISOR ${leccion2.ruta}'), findsOneWidget);
    });

    testWidgets('si faltan archivos muestra un mensaje claro',
        (tester) async {
      when(() => repositorio.obtenerRecursosLocales(any()))
          .thenThrow(const ContenidoIncompletoException('falta'));
      when(() => repositorio.obtenerModulo(any()))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(
        app(
          LectorModuloScreen(
            modulo: descargado,
            construirVisor: visorFalso,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Faltan archivos de este módulo. Descárgalo de nuevo.'),
        findsOneWidget,
      );
      expect(find.text('Volver'), findsOneWidget);
    });
  });

  group('Mis descargas (HU05)', () {
    final descargado = moduloDePrueba(
      estado: EstadoDescarga.descargado,
      rutaLocal: '/datos/modulos/lg-grado-3-01',
    );

    testWidgets('el diálogo devuelve false al cancelar y true al confirmar',
        (tester) async {
      final respuestas = <bool>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => respuestas.add(
                await ConfirmarEliminarDialog.mostrar(context, 'Lenguaje 1'),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar "Lenguaje 1"?'), findsOneWidget);
      expect(find.textContaining('Tu progreso no se pierde'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(respuestas, [false, true]);
    });

    testWidgets('lista los módulos guardados como disponibles sin conexión',
        (tester) async {
      when(() => repositorio.obtenerDescargados())
          .thenAnswer((_) async => [descargado]);

      await tester.pumpWidget(app(const MisDescargasScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Lenguaje - Módulo 1'), findsOneWidget);
      expect(find.text('Disponible sin conexión'), findsOneWidget);
      expect(find.text('Abrir'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
    });

    testWidgets('cancelar en el diálogo no elimina nada', (tester) async {
      when(() => repositorio.obtenerDescargados())
          .thenAnswer((_) async => [descargado]);

      await tester.pumpWidget(app(const MisDescargasScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(() => repositorio.eliminarDescarga(any()));
      expect(find.text('Lenguaje - Módulo 1'), findsOneWidget);
    });

    testWidgets('confirmar elimina el módulo de la lista', (tester) async {
      var descargados = [descargado];
      when(() => repositorio.obtenerDescargados())
          .thenAnswer((_) async => descargados);
      when(() => repositorio.eliminarDescarga(any())).thenAnswer((_) async {
        descargados = [];
      });
      when(() => repositorio.obtenerModulo(any()))
          .thenAnswer((_) async => moduloDePrueba());

      await tester.pumpWidget(app(const MisDescargasScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      // Botón "Eliminar" del diálogo.
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Eliminar'),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => repositorio.eliminarDescarga(any())).called(1);
      expect(find.text('Aún no tienes módulos descargados.'), findsOneWidget);
      expect(
        find.text('Se eliminó "Lenguaje - Módulo 1" del dispositivo.'),
        findsOneWidget,
      );
    });

    testWidgets('sin descargas invita a ver los módulos', (tester) async {
      when(() => repositorio.obtenerDescargados())
          .thenAnswer((_) async => []);

      await tester.pumpWidget(app(const MisDescargasScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Aún no tienes módulos descargados.'), findsOneWidget);
      expect(find.text('Ver módulos'), findsOneWidget);
    });
  });
}
