import 'dart:math';

import 'package:flutter/material.dart';

/// Lluvia de confeti para celebrar al terminar un juego. Dura unos segundos
/// y no bloquea los toques.
class Confeti extends StatefulWidget {
  final Duration duracion;

  const Confeti({
    super.key,
    this.duracion = const Duration(milliseconds: 2500),
  });

  @override
  State<Confeti> createState() => _ConfetiState();
}

class _ConfetiState extends State<Confeti> with SingleTickerProviderStateMixin {
  static const List<Color> _colores = [
    Color(0xFFF2A900),
    Color(0xFF0DBA82),
    Color(0xFF1E6092),
    Color(0xFFE53935),
    Color(0xFF8E44AD),
  ];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duracion,
  )..forward();

  late final List<_Papelito> _papelitos = _crear();

  List<_Papelito> _crear() {
    final random = Random(7);

    return [
      for (var i = 0; i < 70; i++)
        _Papelito(
          x: random.nextDouble(),
          retraso: random.nextDouble() * 0.35,
          velocidad: 0.7 + random.nextDouble() * 0.6,
          giro: random.nextDouble() * pi * 2,
          vaiven: random.nextDouble() * 0.06,
          color: _colores[i % _colores.length],
        ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _PintorConfeti(_papelitos, _controller.value),
        ),
      ),
    );
  }
}

class _Papelito {
  final double x;
  final double retraso;
  final double velocidad;
  final double giro;
  final double vaiven;
  final Color color;

  const _Papelito({
    required this.x,
    required this.retraso,
    required this.velocidad,
    required this.giro,
    required this.vaiven,
    required this.color,
  });
}

class _PintorConfeti extends CustomPainter {
  final List<_Papelito> papelitos;
  final double progreso;

  _PintorConfeti(this.papelitos, this.progreso);

  @override
  void paint(Canvas canvas, Size size) {
    if (progreso >= 1) {
      return;
    }

    final pintura = Paint();

    for (final papelito in papelitos) {
      final t = ((progreso - papelito.retraso) / (1 - papelito.retraso))
          .clamp(0.0, 1.0)
          .toDouble();

      if (t <= 0) {
        continue;
      }

      final y = -20 + t * papelito.velocidad * (size.height + 40);
      final x = (papelito.x + sin(t * 10 + papelito.giro) * papelito.vaiven) *
          size.width;

      pintura.color = papelito.color.withValues(alpha: 1 - t * 0.6);

      canvas
        ..save()
        ..translate(x, y)
        ..rotate(papelito.giro + t * 8)
        ..drawRect(const Rect.fromLTWH(-5, -3, 10, 6), pintura)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_PintorConfeti anterior) =>
      anterior.progreso != progreso;
}
