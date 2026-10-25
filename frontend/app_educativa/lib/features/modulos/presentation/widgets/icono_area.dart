import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Ícono de un área educativa dentro de un cuadro de color, como en el
/// diseño. Las áreas sin ícono propio usan uno genérico.
class IconoArea extends StatelessWidget {
  final String area;
  final double tamano;

  const IconoArea({
    super.key,
    required this.area,
    this.tamano = 52,
  });

  static (IconData, Color, Color) _apariencia(String area) {
    final nombre = area.toLowerCase();

    if (nombre.contains('social')) {
      return (Icons.public_rounded, AppTheme.ambar, AppTheme.ambarSuave);
    }
    if (nombre.contains('lenguaje') || nombre.contains('español')) {
      return (Icons.menu_book_rounded, AppTheme.azul, AppTheme.azulClaro);
    }
    if (nombre.contains('matem')) {
      return (Icons.calculate_rounded, AppTheme.verde, AppTheme.verdeSuave);
    }
    if (nombre.contains('natural')) {
      return (Icons.eco_rounded, AppTheme.verde, AppTheme.verdeSuave);
    }

    return (Icons.school_rounded, AppTheme.gris, AppTheme.grisSuave);
  }

  @override
  Widget build(BuildContext context) {
    final (icono, color, fondo) = _apariencia(area);

    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(tamano * 0.28),
      ),
      child: Icon(icono, color: color, size: tamano * 0.55),
    );
  }
}
