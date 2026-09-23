import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

    expect(find.text('¡Hola!'), findsOneWidget);
    expect(find.text('¿Cómo te llamas?'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);
  });
}