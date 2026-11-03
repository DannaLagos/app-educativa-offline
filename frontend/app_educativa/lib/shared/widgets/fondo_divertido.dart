import 'dart:math';

import 'package:flutter/material.dart';

/// Fondo de paisaje suave: cielo claro con un sol pálido, nubes y colinas
/// en tonos pastel, sin bordes, para que no compita con el contenido. Se
/// dibuja con código (no usa imágenes), así que funciona sin internet, y es
/// estático: no gasta batería.
class FondoDivertido extends StatelessWidget {
  final Widget child;

  const FondoDivertido({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Siempre llena la pantalla, aunque el contenido sea corto.
    return SizedBox.expand(
      child: CustomPaint(
        painter: const _PintorPaisaje(),
        child: child,
      ),
    );
  }
}

class _PintorPaisaje extends CustomPainter {
  static const Color _cieloArriba = Color(0xFFB3E0FF);
  static const Color _cieloAbajo = Color(0xFFEFF9FF);
  static const Color _sol = Color(0xFFFFE38A);
  static const Color _sombraNube = Color(0xFFD6ECFA);
  static const Color _colinaLejana = Color(0xFFDDF3CF);
  static const Color _colinaAtras = Color(0xFFC7EBB4);
  static const Color _colinaAdelante = Color(0xFFA9DE9C);

  const _PintorPaisaje();

  @override
  void paint(Canvas canvas, Size size) {
    final todo = Offset.zero & size;

    canvas.drawRect(
      todo,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_cieloArriba, _cieloAbajo],
          stops: [0, 0.7],
        ).createShader(todo),
    );

    // El sol queda en la esquina, medio escondido: no tapa los botones de
    // arriba.
    _dibujarSol(canvas, Offset(size.width - 10, 18));
    _destellos(canvas, size);
    _nube(canvas, Offset(size.width * 0.12, size.height * 0.16), 1);
    _nube(canvas, Offset(size.width * 0.62, size.height * 0.34), 0.8);
    _nube(canvas, Offset(size.width * 0.08, size.height * 0.55), 0.7);
    _colinas(canvas, size);
  }

  void _dibujarSol(Canvas canvas, Offset centro) {
    // Halo: el sol se difumina en el cielo.
    canvas.drawCircle(
      centro,
      120,
      Paint()
        ..shader = RadialGradient(
          colors: [_sol.withValues(alpha: 0.55), _sol.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: centro, radius: 120)),
    );
    canvas.drawCircle(centro, 46, Paint()..color = _sol);
  }

  void _destellos(Canvas canvas, Size size) {
    final azar = Random(7);
    final punto = Paint()..color = Colors.white.withValues(alpha: 0.6);

    for (var i = 0; i < 12; i++) {
      final centro = Offset(
        azar.nextDouble() * size.width,
        azar.nextDouble() * size.height * 0.7,
      );
      final r = 1.5 + azar.nextDouble() * 2.5;
      // Destello de cuatro puntas.
      canvas.drawPath(
        Path()
          ..moveTo(centro.dx, centro.dy - r * 2)
          ..quadraticBezierTo(
              centro.dx, centro.dy, centro.dx + r * 2, centro.dy)
          ..quadraticBezierTo(
              centro.dx, centro.dy, centro.dx, centro.dy + r * 2)
          ..quadraticBezierTo(
              centro.dx, centro.dy, centro.dx - r * 2, centro.dy)
          ..quadraticBezierTo(
              centro.dx, centro.dy, centro.dx, centro.dy - r * 2)
          ..close(),
        punto,
      );
    }
  }

  /// Nube esponjosa con una sombra azul muy clara debajo, sin bordes.
  void _nube(Canvas canvas, Offset base, double escala) {
    final circulos = [
      (const Offset(0, 0), 26.0),
      (const Offset(30, -16), 32.0),
      (const Offset(64, -4), 26.0),
      (const Offset(88, 8), 18.0),
      (const Offset(-20, 10), 18.0),
    ];
    const piso = Rect.fromLTRB(-30, 4, 100, 26);

    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(escala);

    void dibujar(Offset corrimiento, Paint pintura) {
      for (final (centro, radio) in circulos) {
        canvas.drawCircle(centro + corrimiento, radio, pintura);
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            piso.shift(corrimiento), const Radius.circular(11)),
        pintura,
      );
    }

    dibujar(const Offset(0, 6), Paint()..color = _sombraNube);
    dibujar(Offset.zero, Paint()..color = Colors.white.withValues(alpha: 0.9));
    canvas.restore();
  }

  void _colinas(Canvas canvas, Size size) {
    final alto = size.height;
    final ancho = size.width;

    final lejana = Path()
      ..moveTo(0, alto)
      ..lineTo(0, alto - 190)
      ..quadraticBezierTo(ancho * 0.2, alto - 240, ancho * 0.45, alto - 200)
      ..quadraticBezierTo(ancho * 0.75, alto - 160, ancho, alto - 220)
      ..lineTo(ancho, alto)
      ..close();
    canvas.drawPath(lejana, Paint()..color = _colinaLejana);

    final atras = Path()
      ..moveTo(0, alto)
      ..lineTo(0, alto - 150)
      ..quadraticBezierTo(ancho * 0.3, alto - 210, ancho * 0.62, alto - 150)
      ..quadraticBezierTo(ancho * 0.85, alto - 110, ancho, alto - 160)
      ..lineTo(ancho, alto)
      ..close();
    canvas.drawPath(atras, Paint()..color = _colinaAtras);

    final adelante = Path()
      ..moveTo(0, alto)
      ..lineTo(0, alto - 80)
      ..quadraticBezierTo(ancho * 0.35, alto - 130, ancho * 0.7, alto - 70)
      ..quadraticBezierTo(ancho * 0.88, alto - 45, ancho, alto - 90)
      ..lineTo(ancho, alto)
      ..close();
    canvas.drawPath(adelante, Paint()..color = _colinaAdelante);

    // Florecitas sobre el pasto, pequeñas y suaves.
    final azar = Random(3);
    for (var i = 0; i < 6; i++) {
      final centro = Offset(
        ancho * (0.08 + i * 0.16 + azar.nextDouble() * 0.05),
        alto - 30 - azar.nextDouble() * 30,
      );
      final petalo = Paint()
        ..color = (i.isEven ? Colors.white : const Color(0xFFFFB3C6))
            .withValues(alpha: 0.9);
      for (var p = 0; p < 5; p++) {
        final angulo = 2 * pi * p / 5;
        canvas.drawCircle(
          centro + Offset(cos(angulo), sin(angulo)) * 3.5,
          3,
          petalo,
        );
      }
      canvas.drawCircle(centro, 2.2, Paint()..color = _sol);
    }
  }

  @override
  bool shouldRepaint(_PintorPaisaje anterior) => false;
}
