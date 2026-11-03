import 'dart:math';

import 'package:app_educativa/features/actividades/presentation/screens/juego_screen.dart';
import 'package:app_educativa/features/mascota/domain/mascota.dart';
import 'package:app_educativa/features/mascota/presentation/mascota_scope.dart';
import 'package:app_educativa/features/mascota/presentation/widgets/mascota_animada.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'datos_actividades.dart';

void main() {
  testWidgets(
      'la mascota del niño acompaña el juego y recibe las estrellas al final',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MascotaScope(
        mascota: ValueNotifier(MascotaElegida.de(EspecieMascota.lumi)),
        child: MaterialApp(
          // La mascota se mueve sin parar; quieta, pumpAndSettle termina.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: JuegoScreen(
            moduloId: 'cs-grado-1',
            plan: plan,
            actividad: elige,
            random: Random(1),
            pausa: Duration.zero,
          ),
        ),
      ),
    );

    expect(find.byType(MascotaAnimada), findsOneWidget);
    expect(find.text(elige.instruccion), findsOneWidget);

    await tester.tap(find.text('Oreja'));
    await tester.pump();
    await tester.tap(find.text('Mano'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ojos'));
    await tester.pumpAndSettle();

    // 2 aciertos y 1 error: dos estrellas para la mascota.
    expect(find.text('+2 ⭐ para Lumi'), findsOneWidget);
    expect(find.byType(MascotaAnimada), findsOneWidget);
  });

  testWidgets('sin mascota elegida el juego funciona igual', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: JuegoScreen(
          moduloId: 'cs-grado-1',
          plan: plan,
          actividad: elige,
          random: Random(1),
          pausa: Duration.zero,
        ),
      ),
    );

    expect(find.byType(MascotaAnimada), findsNothing);
    expect(find.text(elige.instruccion), findsOneWidget);
  });
}
