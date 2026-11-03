import 'dart:io';

import 'package:app_educativa/shared/widgets/dibujo.dart';
import 'package:app_educativa/shared/widgets/dibujos_disponibles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dibujo', () {
    test('el nombre del archivo es el código Unicode sin FE0F', () {
      expect(Dibujo.codigo('🍎'), '1f34e');
      // Con y sin selector de variación da lo mismo.
      expect(Dibujo.codigo('✏️'), Dibujo.codigo('✏'));
      // Los emojis compuestos conservan sus partes.
      expect(Dibujo.codigo('👨‍🍳'), '1f468-200d-1f373');
    });

    test('cada dibujo de la lista tiene su archivo en assets/dibujos', () {
      final faltan = [
        for (final codigo in dibujosDisponibles)
          if (!File('assets/dibujos/$codigo.png').existsSync()) codigo,
      ];

      expect(faltan, isEmpty);
      expect(File('assets/dibujos/LICENSE.txt').existsSync(), isTrue);
    });

    testWidgets('muestra la ilustración si existe', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Dibujo('🍎', tamano: 50)),
      );

      final imagen = tester.widget<Image>(find.byType(Image));
      expect(
        (imagen.image as AssetImage).assetName,
        'assets/dibujos/1f34e.png',
      );
    });

    testWidgets('sin ilustración muestra el emoji normal', (tester) async {
      // Las banderas no están en Fluent Emoji.
      expect(Dibujo.tieneIlustracion('🇨🇴'), isFalse);

      await tester.pumpWidget(const MaterialApp(home: Dibujo('🇨🇴')));

      expect(find.byType(Image), findsNothing);
      expect(find.text('🇨🇴'), findsOneWidget);
    });
  });
}
