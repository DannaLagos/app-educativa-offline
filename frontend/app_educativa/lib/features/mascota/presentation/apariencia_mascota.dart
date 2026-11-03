import 'package:flutter/material.dart';

import '../domain/mascota.dart';

/// Colores de cada mascota: el del cuerpo, uno claro para la barriga y un
/// acento para cuernos, branquias, orejas, flores o rayos.
class AparienciaMascota {
  final Color principal;
  final Color claro;
  final Color acento;

  const AparienciaMascota({
    required this.principal,
    required this.claro,
    required this.acento,
  });

  static AparienciaMascota de(EspecieMascota especie) {
    return switch (especie) {
      EspecieMascota.chispa => const AparienciaMascota(
          principal: Color(0xFFFF7A45),
          claro: Color(0xFFFFD166),
          acento: Color(0xFFE63946),
        ),
      EspecieMascota.burbu => const AparienciaMascota(
          principal: Color(0xFF2EC4B6),
          claro: Color(0xFFB8F2E6),
          acento: Color(0xFFFF6FB5),
        ),
      EspecieMascota.lumi => const AparienciaMascota(
          principal: Color(0xFF8E5CF7),
          claro: Color(0xFFE4D7FF),
          acento: Color(0xFFFFC93C),
        ),
      EspecieMascota.brote => const AparienciaMascota(
          principal: Color(0xFF7ED957),
          claro: Color(0xFFE6FFD1),
          acento: Color(0xFFFF8FAB),
        ),
      EspecieMascota.nimbo => const AparienciaMascota(
          principal: Color(0xFF4FA3FF),
          claro: Color(0xFFDCEEFF),
          acento: Color(0xFFFFD43B),
        ),
    };
  }

  /// Fondo suave para tarjetas y para la mascota elegida.
  Color get fondo => Color.lerp(claro, Colors.white, 0.55)!;

  /// Versión oscura del color principal, para textos con buen contraste.
  Color get oscuro => Color.lerp(principal, Colors.black, 0.45)!;
}
