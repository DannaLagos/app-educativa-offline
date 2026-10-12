import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Logo de la app: libro sobre un cuadro azul claro y, opcionalmente, el
/// nombre "Aprendo".
class LogoAprendo extends StatelessWidget {
  final double tamano;
  final bool conNombre;

  const LogoAprendo({
    super.key,
    this.tamano = 72,
    this.conNombre = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: tamano,
          height: tamano,
          decoration: BoxDecoration(
            color: AppTheme.azulClaro,
            borderRadius: BorderRadius.circular(tamano * 0.28),
          ),
          child: Icon(
            Icons.menu_book_rounded,
            size: tamano * 0.55,
            color: AppTheme.azul,
          ),
        ),
        if (conNombre) ...[
          const SizedBox(height: 12),
          Text(
            'Aprendo',
            style: TextStyle(
              fontSize: tamano * 0.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.azul,
            ),
          ),
        ],
      ],
    );
  }
}
