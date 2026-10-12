import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_educativa/features/perfil/presentation/screens/bienvenida_screen.dart';
import 'package:app_educativa/features/perfil/presentation/screens/crear_perfil_screen.dart';

void main() {
  testWidgets('Muestra la pantalla de creación de perfil', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CrearPerfilScreen(),
      ),
    );

    expect(find.text('Crea tu perfil'), findsOneWidget);
    expect(find.text('¿Cómo te llamas?'), findsOneWidget);
    expect(find.text('¡Listos, continuar!'), findsOneWidget);
  });

  testWidgets('La bienvenida lleva a crear el perfil', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BienvenidaScreen(),
      ),
    );

    expect(find.text('Aprendo'), findsOneWidget);
    expect(find.text('¡Hola, amiguito!'), findsOneWidget);

    await tester.ensureVisible(find.text('Comenzar aventura'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar aventura'));
    await tester.pumpAndSettle();

    expect(find.text('Crea tu perfil'), findsOneWidget);
  });
}
