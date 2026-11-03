import 'dart:async';

import 'package:app_educativa/core/network/conectividad_service.dart';
import 'package:app_educativa/features/progreso/data/progreso_repository.dart';
import 'package:app_educativa/features/progreso/domain/resultado_sincronizacion.dart';
import 'package:app_educativa/features/sincronizacion/presentation/sincronizacion_controller.dart';
import 'package:app_educativa/features/sincronizacion/presentation/sincronizacion_scope.dart';
import 'package:app_educativa/features/sincronizacion/presentation/widgets/barra_conexion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProgresoRepository extends Mock implements ProgresoRepository {}

/// Conectividad falsa: la prueba decide cuándo hay red y cuándo se pierde.
class ConectividadFalsa implements ConectividadService {
  final _cambios = StreamController<bool>.broadcast();
  bool hayRed;

  ConectividadFalsa({this.hayRed = true});

  void cambiar(bool valor) {
    hayRed = valor;
    _cambios.add(valor);
  }

  @override
  Future<bool> hayConexion() async => hayRed;

  @override
  Stream<bool> get cambios => _cambios.stream;

  Future<void> cerrar() => _cambios.close();
}

/// Deja correr los futuros y temporizadores pendientes.
Future<void> esperar([int milisegundos = 20]) =>
    Future<void>.delayed(Duration(milliseconds: milisegundos));

void main() {
  late MockProgresoRepository repositorio;
  late ConectividadFalsa conectividad;
  late SincronizacionController controller;
  var pendientes = 0;

  SincronizacionController crear({
    Duration esperaReintento = const Duration(minutes: 1),
  }) {
    return SincronizacionController(
      repositorio: repositorio,
      conectividad: conectividad,
      esperaTrasCambio: Duration.zero,
      esperaReintento: esperaReintento,
    );
  }

  setUp(() {
    pendientes = 0;
    repositorio = MockProgresoRepository();
    conectividad = ConectividadFalsa();

    when(() => repositorio.contarPendientes())
        .thenAnswer((_) async => pendientes);
    when(() => repositorio.ultimaSincronizacion())
        .thenAnswer((_) async => null);
    when(() => repositorio.sincronizar()).thenAnswer((_) async {
      final enviados = pendientes;
      pendientes = 0;
      return enviados == 0 ? const SinPendientes() : Enviado(enviados);
    });

    controller = crear();
  });

  tearDown(() async {
    controller.dispose();
    await conectividad.cerrar();
  });

  test('CA1: al perder la conexión avisa que está sin internet', () async {
    await controller.iniciar();
    expect(controller.hayConexion, isTrue);

    var avisos = 0;
    controller.addListener(() => avisos++);

    conectividad.cambiar(false);
    await esperar();

    expect(controller.hayConexion, isFalse);
    expect(avisos, greaterThan(0));
  });

  test('CA2: sin conexión los avances quedan pendientes y no se envían',
      () async {
    conectividad.hayRed = false;
    await controller.iniciar();

    pendientes = 3;
    controller.alCambiarProgreso();
    await esperar();

    expect(controller.pendientes, 3);
    expect(controller.estado, EstadoSincronizacion.pendiente);
    verifyNever(() => repositorio.sincronizar());
  });

  test('CA4: al volver la conexión reintenta enviar lo pendiente', () async {
    conectividad.hayRed = false;
    await controller.iniciar();
    pendientes = 2;
    controller.alCambiarProgreso();
    await esperar();

    conectividad.cambiar(true);
    await esperar();

    verify(() => repositorio.sincronizar()).called(1);
    expect(controller.pendientes, 0);
    expect(controller.estado, EstadoSincronizacion.alDia);
    expect(controller.ultimaSincronizacion, isNotNull);
  });

  test('al abrir la app con internet envía lo que había pendiente', () async {
    pendientes = 4;

    await controller.iniciar();

    verify(() => repositorio.sincronizar()).called(1);
    expect(controller.pendientes, 0);
  });

  test('CA3: si el envío falla, los datos siguen pendientes y se reintenta',
      () async {
    controller.dispose();
    controller = crear(esperaReintento: const Duration(milliseconds: 50));

    var intentos = 0;
    when(() => repositorio.sincronizar()).thenAnswer((_) async {
      intentos++;
      if (intentos == 1) {
        return FalloSincronizacion(Exception('servidor caído'), pendientes);
      }
      pendientes = 0;
      return const Enviado(1);
    });

    pendientes = 1;
    await controller.iniciar();

    expect(controller.estado, EstadoSincronizacion.error);
    expect(controller.pendientes, 1, reason: 'no se pierde nada');

    await esperar(120);

    expect(intentos, 2);
    expect(controller.estado, EstadoSincronizacion.alDia);
  });

  test('al abrir la app muestra la última sincronización guardada', () async {
    final guardada = DateTime(2026, 10, 24, 9, 30);
    when(() => repositorio.ultimaSincronizacion())
        .thenAnswer((_) async => guardada);

    await controller.iniciar();

    expect(controller.ultimaSincronizacion, guardada);
  });

  test('un error inesperado del repositorio no rompe la app', () async {
    when(() => repositorio.sincronizar()).thenThrow(StateError('fallo'));
    pendientes = 1;

    await controller.iniciar();

    expect(controller.estado, EstadoSincronizacion.error);
    expect(controller.pendientes, 1);
  });

  group('pantallas', () {
    Widget app(SincronizacionController controller) {
      return SincronizacionScope(
        controller: controller,
        child: const MaterialApp(
          builder: BarraConexion.envolver,
          home: Scaffold(
            body: Column(children: [Text('Inicio'), TarjetaSincronizacion()]),
          ),
        ),
      );
    }

    testWidgets('CA1: sin internet se muestra la barra de aviso',
        (tester) async {
      conectividad.hayRed = false;
      pendientes = 2;
      await tester.runAsync(controller.iniciar);

      await tester.pumpWidget(app(controller));

      expect(find.byKey(const ValueKey('barra-sin-conexion')), findsOneWidget);
      expect(
        find.text('Sin internet · Tu progreso se guarda en el teléfono'),
        findsOneWidget,
      );
      expect(find.text('Tienes 2 avances por enviar'), findsOneWidget);
      expect(find.textContaining('cuando vuelva el internet'), findsOneWidget);
    });

    testWidgets('con internet y todo enviado no hay barra', (tester) async {
      await tester.runAsync(controller.iniciar);

      await tester.pumpWidget(app(controller));

      expect(find.byKey(const ValueKey('barra-sin-conexion')), findsNothing);
      expect(find.text('Todo tu progreso está enviado'), findsOneWidget);
    });

    testWidgets('CA3: si falló, avisa que está guardado y deja reintentar',
        (tester) async {
      when(() => repositorio.sincronizar()).thenAnswer(
        (_) async => FalloSincronizacion(Exception('x'), pendientes),
      );
      pendientes = 1;
      await tester.runAsync(controller.iniciar);

      await tester.pumpWidget(app(controller));

      expect(
        find.byKey(const ValueKey('barra-error-sincronizacion')),
        findsOneWidget,
      );
      expect(find.text('No se pudo enviar 1 avance'), findsOneWidget);
      expect(find.byKey(const ValueKey('boton-reintentar')), findsOneWidget);
    });
  });
}
