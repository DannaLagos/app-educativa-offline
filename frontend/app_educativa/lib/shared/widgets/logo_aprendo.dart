import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class LogoAprendo extends StatelessWidget {
  static const double _tamano = 80;
  static const double _proporcionTexto = 0.6;

  static const List<Color> _arcoiris = [
    AppTheme.naranja,
    AppTheme.rosa,
    AppTheme.morado,
    AppTheme.azul,
    AppTheme.turquesa,
  ];

  const LogoAprendo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: -0.08,
          child: Container(
            width: _tamano,
            height: _tamano,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.amarillo, AppTheme.naranja],
              ),
              borderRadius: BorderRadius.circular(_tamano * 0.3),
              boxShadow: const [
                BoxShadow(color: Color(0x40C2410C), offset: Offset(0, 6)),
              ],
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: _tamano * 0.58,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (limites) =>
              const LinearGradient(colors: _arcoiris).createShader(limites),
          child: const Text(
            'Aprendo',
            style: TextStyle(
              fontSize: _tamano * _proporcionTexto,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}
