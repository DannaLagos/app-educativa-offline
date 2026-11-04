import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Colores vivos para tarjetas, opciones, canastas y casillas de los juegos.
/// Todos llevan texto blanco con buen contraste.
const List<Color> coloresJuego = [
  AppTheme.azul,
  AppTheme.naranja,
  AppTheme.morado,
  AppTheme.verde,
  AppTheme.rosa,
  AppTheme.turquesa,
];

Color colorJuego(int indice) => coloresJuego[indice % coloresJuego.length];

/// Versión muy clara de [color], para fondos.
Color suave(Color color) => Color.lerp(color, Colors.white, 0.86)!;

/// Versión oscura de [color], para el relieve de botones y tarjetas.
Color relieve(Color color) => Color.lerp(color, Colors.black, 0.3)!;

/// Base de los efectos de una sola vez: se disparan cuando [veces] aumenta.
abstract class _EfectoUnaVez extends StatefulWidget {
  final int veces;
  final Widget child;
  final Duration duracion;

  const _EfectoUnaVez({
    super.key,
    required this.veces,
    required this.child,
    required this.duracion,
  });
}

abstract class _EstadoEfecto<T extends _EfectoUnaVez> extends State<T>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: widget.duracion,
  );

  @override
  void didUpdateWidget(T anterior) {
    super.didUpdateWidget(anterior);

    if (widget.veces > anterior.veces &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// Sacude a su hijo de lado a lado: así se marca un error con suavidad.
class Sacudir extends _EfectoUnaVez {
  const Sacudir({super.key, required super.veces, required super.child})
      : super(duracion: const Duration(milliseconds: 420));

  @override
  State<Sacudir> createState() => _SacudirState();
}

class _SacudirState extends _EstadoEfecto<Sacudir> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: widget.child,
      builder: (context, hijo) {
        final t = controller.value;
        // Tres vaivenes que se van apagando.
        final dx = sin(t * pi * 6) * 10 * (1 - t);

        return Transform.translate(offset: Offset(dx, 0), child: hijo);
      },
    );
  }
}

/// Hace rebotar a su hijo (crece y vuelve): así se celebra un acierto.
class Rebotar extends _EfectoUnaVez {
  const Rebotar({super.key, required super.veces, required super.child})
      : super(duracion: const Duration(milliseconds: 450));

  @override
  State<Rebotar> createState() => _RebotarState();
}

class _RebotarState extends _EstadoEfecto<Rebotar> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: widget.child,
      builder: (context, hijo) {
        final escala = 1 + 0.16 * sin(controller.value * pi);

        return Transform.scale(scale: escala, child: hijo);
      },
    );
  }
}

/// Hace aparecer a su hijo con un saltito la primera vez que se dibuja.
class Aparecer extends StatelessWidget {
  final Widget child;

  const Aparecer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return child;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      child: child,
      builder: (context, escala, hijo) =>
          Transform.scale(scale: escala, child: hijo),
    );
  }
}

/// Estrellas que salen disparadas desde el centro y se desvanecen. Dura
/// menos de un segundo y no bloquea los toques.
class EstallidoEstrellas extends StatefulWidget {
  final double tamano;
  final List<Color> colores;

  const EstallidoEstrellas({
    super.key,
    this.tamano = 220,
    this.colores = const [
      Color(0xFFFFC93C),
      Color(0xFFFF7EB6),
      Color(0xFF5BD47A),
      Color(0xFF4FA3FF),
    ],
  });

  @override
  State<EstallidoEstrellas> createState() => _EstallidoEstrellasState();
}

class _EstallidoEstrellasState extends State<EstallidoEstrellas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: widget.tamano,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _PintorEstallido(_controller.value, widget.colores),
          ),
        ),
      ),
    );
  }
}

class _PintorEstallido extends CustomPainter {
  static const int _cantidad = 12;

  final double t;
  final List<Color> colores;

  _PintorEstallido(this.t, this.colores);

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) {
      return;
    }

    final centro = size.center(Offset.zero);
    final avance = Curves.easeOutCubic.transform(t);
    final pintura = Paint();

    for (var i = 0; i < _cantidad; i++) {
      final angulo = 2 * pi * i / _cantidad + (i.isEven ? 0.2 : 0);
      final distancia = avance * size.width * (i.isEven ? 0.45 : 0.32);
      final punto = centro + Offset(cos(angulo), sin(angulo)) * distancia;

      pintura.color = colores[i % colores.length].withValues(alpha: 1 - t);
      dibujarEstrella(canvas, punto, (i.isEven ? 11 : 7) * (1 - t * 0.4), pintura);
    }
  }

  @override
  bool shouldRepaint(_PintorEstallido anterior) => anterior.t != t;
}

void dibujarEstrella(
  Canvas canvas,
  Offset centro,
  double radio,
  Paint pintura, {
  int puntas = 5,
}) {
  final camino = Path();

  for (var i = 0; i < puntas * 2; i++) {
    final r = i.isEven ? radio : radio * 0.45;
    final angulo = -pi / 2 + pi * i / puntas;
    final punto = centro + Offset(cos(angulo), sin(angulo)) * r;
    i == 0 ? camino.moveTo(punto.dx, punto.dy) : camino.lineTo(punto.dx, punto.dy);
  }

  canvas.drawPath(camino..close(), pintura);
}
