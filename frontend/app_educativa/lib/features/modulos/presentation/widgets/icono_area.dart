import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/icono_en_cuadro.dart';

class IconoArea extends StatelessWidget {
  static const double tamanoNormal = 52;

  final String area;
  final double tamano;

  const IconoArea({
    super.key,
    required this.area,
    this.tamano = tamanoNormal,
  });

  @override
  Widget build(BuildContext context) {
    final (icono, colores) = _elegirApariencia(area);

    return IconoEnCuadro(icono: icono, colores: colores, tamano: tamano);
  }

  static (IconData, ({Color icono, Color fondo})) _elegirApariencia(
    String area,
  ) {
    final nombre = area.toLowerCase();

    if (nombre.contains('social')) {
      return (
        Icons.public_rounded,
        (icono: AppTheme.ambar, fondo: AppTheme.ambarSuave),
      );
    }
    if (nombre.contains('lenguaje') || nombre.contains('español')) {
      return (
        Icons.menu_book_rounded,
        (icono: AppTheme.azul, fondo: AppTheme.azulClaro),
      );
    }
    if (nombre.contains('matem')) {
      return (
        Icons.calculate_rounded,
        (icono: AppTheme.verde, fondo: AppTheme.verdeSuave),
      );
    }
    if (nombre.contains('natural')) {
      return (
        Icons.eco_rounded,
        (icono: AppTheme.verde, fondo: AppTheme.verdeSuave),
      );
    }

    return (
      Icons.school_rounded,
      (icono: AppTheme.gris, fondo: AppTheme.grisSuave),
    );
  }
}
