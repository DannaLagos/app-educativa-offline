import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/icono_en_cuadro.dart';

/// Ícono y colores de cada área: cada materia tiene su propio color vivo
/// para que los niños la reconozcan aunque todavía no lean bien.
class AparienciaArea {
  final IconData icono;

  /// Ilustración 3D del área (ver [Dibujo]), para las tarjetas grandes.
  final String emoji;
  final Color color;
  final Color suave;

  const AparienciaArea({
    required this.icono,
    required this.emoji,
    required this.color,
    required this.suave,
  });

  static AparienciaArea de(String area) {
    final nombre = area.toLowerCase();

    if (nombre.contains('social')) {
      return const AparienciaArea(
        icono: Icons.public_rounded,
        emoji: '🌍',
        color: AppTheme.naranja,
        suave: AppTheme.naranjaSuave,
      );
    }
    if (nombre.contains('lenguaje') || nombre.contains('español')) {
      return const AparienciaArea(
        icono: Icons.menu_book_rounded,
        emoji: '📖',
        color: AppTheme.morado,
        suave: AppTheme.moradoSuave,
      );
    }
    if (nombre.contains('matem')) {
      return const AparienciaArea(
        icono: Icons.calculate_rounded,
        emoji: '🔢',
        color: AppTheme.azul,
        suave: AppTheme.azulClaro,
      );
    }
    if (nombre.contains('natural')) {
      return const AparienciaArea(
        icono: Icons.eco_rounded,
        emoji: '🌱',
        color: AppTheme.verde,
        suave: AppTheme.verdeSuave,
      );
    }

    return const AparienciaArea(
      icono: Icons.school_rounded,
      emoji: '📚',
      color: AppTheme.rosa,
      suave: AppTheme.rosaSuave,
    );
  }
}

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
    final apariencia = AparienciaArea.de(area);

    return IconoEnCuadro(
      icono: apariencia.icono,
      colores: (icono: apariencia.color, fondo: apariencia.suave),
      tamano: tamano,
    );
  }
}
