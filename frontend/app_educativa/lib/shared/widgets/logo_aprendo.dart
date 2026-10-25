import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'icono_en_cuadro.dart';

class LogoAprendo extends StatelessWidget {
  static const double _tamano = 72;
  static const double _proporcionTexto = 0.5;

  const LogoAprendo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconoEnCuadro(
          icono: Icons.menu_book_rounded,
          colores: (icono: AppTheme.azul, fondo: AppTheme.azulClaro),
          tamano: _tamano,
        ),
        SizedBox(height: 12),
        Text(
          'Aprendo',
          style: TextStyle(
            fontSize: _tamano * _proporcionTexto,
            fontWeight: FontWeight.w800,
            color: AppTheme.azul,
          ),
        ),
      ],
    );
  }
}
