import 'package:app_educativa/core/voz/lector_voz.dart';
import 'package:app_educativa/shared/widgets/boton_escuchar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Voz de un teléfono con o sin motor de voz instalado.
class VozDePrueba implements LectorVoz {
  final bool hayMotor;
  final List<String> dicho = [];

  VozDePrueba({required this.hayMotor});

  @override
  Future<void> hablar(String texto) async => dicho.add(texto);

  @override
  Future<void> detener() async {}

  @override
  Future<bool> estaDisponible() async => hayMotor;
}

void main() {
  Future<void> mostrar(WidgetTester tester, LectorVoz voz) {
    return tester.pumpWidget(
      VozScope(
        voz: voz,
        child: const MaterialApp(
          home: Scaffold(body: Center(child: BotonEscuchar(texto: 'Hola'))),
        ),
      ),
    );
  }

  testWidgets('con motor de voz, el botón 🔊 lee el texto', (tester) async {
    final voz = VozDePrueba(hayMotor: true);
    await mostrar(tester, voz);

    await tester.tap(find.byType(BotonEscuchar));
    await tester.pump();

    expect(voz.dicho, ['Hola']);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('sin motor de voz, avisa qué instalar en vez de callar',
      (tester) async {
    final voz = VozDePrueba(hayMotor: false);
    await mostrar(tester, voz);

    await tester.tap(find.byType(BotonEscuchar));
    await tester.pump();

    expect(voz.dicho, isEmpty);
    expect(
      find.textContaining('no tiene voz instalada'),
      findsOneWidget,
    );
  });
}
