import 'dart:async';

import 'package:app_educativa/core/network/conectividad_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity connectivity;
  late StreamController<List<ConnectivityResult>> cambiosRed;
  var hayInternet = true;
  var pruebas = 0;

  ConectividadService crear() {
    return ConectividadService(
      connectivity: connectivity,
      hayInternet: () async {
        pruebas++;
        return hayInternet;
      },
      intervalo: const Duration(milliseconds: 20),
    );
  }

  setUp(() {
    hayInternet = true;
    pruebas = 0;
    connectivity = MockConnectivity();
    cambiosRed = StreamController<List<ConnectivityResult>>.broadcast();

    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(() => connectivity.onConnectivityChanged)
        .thenAnswer((_) => cambiosRed.stream);
  });

  tearDown(() => cambiosRed.close());

  test('sin red no hay conexión (y no hace falta probar el servidor)',
      () async {
    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.none]);

    expect(await crear().hayConexion(), isFalse);
    expect(pruebas, 0);
  });

  test('con wifi pero sin internet, dice que no hay conexión (HU10, CA1)',
      () async {
    hayInternet = false;

    expect(await crear().hayConexion(), isFalse);
  });

  test('con wifi e internet hay conexión', () async {
    expect(await crear().hayConexion(), isTrue);
  });

  test('avisa cuando se pierde el internet aunque el wifi siga activo',
      () async {
    final valores = <bool>[];
    final suscripcion = crear().cambios.listen(valores.add);

    await Future<void>.delayed(const Duration(milliseconds: 60));
    hayInternet = false;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    hayInternet = true;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await suscripcion.cancel();

    // Solo emite cuando el valor cambia.
    expect(valores, [true, false, true]);
  });
}
