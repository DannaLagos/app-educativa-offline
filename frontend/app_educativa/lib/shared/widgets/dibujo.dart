import 'package:flutter/material.dart';

import 'dibujos_disponibles.dart';

/// Muestra un emoji del contenido como ilustración 3D (Fluent Emoji),
/// incluida en la app: se ve igual en todos los teléfonos, también en los
/// viejos donde los emojis nuevos salen como cuadros vacíos.
///
/// Si el emoji no tiene ilustración (por ejemplo, en contenido nuevo), se
/// muestra el emoji normal: nada se rompe.
class Dibujo extends StatelessWidget {
  final String emoji;
  final double tamano;

  const Dibujo(this.emoji, {super.key, this.tamano = 44});

  /// Nombre del archivo: los códigos Unicode sin el selector de variación
  /// FE0F (por ejemplo, "👨‍🍳" → "1f468-200d-1f373").
  static String codigo(String emoji) => emoji.runes
      .where((runa) => runa != 0xFE0F)
      .map((runa) => runa.toRadixString(16))
      .join('-');

  static bool tieneIlustracion(String emoji) =>
      dibujosDisponibles.contains(codigo(emoji));

  @override
  Widget build(BuildContext context) {
    final clave = codigo(emoji);
    // El emoji se dibuja un poco más pequeño que la caja de la imagen.
    final respaldo = Text(emoji, style: TextStyle(fontSize: tamano * 0.85));

    if (!dibujosDisponibles.contains(clave)) {
      return respaldo;
    }

    return Image.asset(
      'assets/dibujos/$clave.png',
      width: tamano,
      height: tamano,
      filterQuality: FilterQuality.medium,
      // Se lee el emoji en voz y en el lector de pantalla por su texto, que
      // ya está junto al dibujo.
      excludeFromSemantics: true,
      errorBuilder: (context, error, stack) => respaldo,
    );
  }
}
