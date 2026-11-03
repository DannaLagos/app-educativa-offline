import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/dibujo.dart';
import '../../domain/actividad.dart';
import '../widgets/efectos.dart';
import '../widgets/tarjeta_elemento.dart';
import 'juego_base.dart';

/// Atrapa: los dibujos suben despacio como globos por un cielo con nubes y
/// el niño revienta solo los que cumplen el objetivo. Los globos que se
/// escapan vuelven a salir por abajo, así que nadie pierde por ser lento.
class JuegoAtrapa extends JuegoBase {
  /// Alto de la zona donde suben los globos.
  static const double altoZona = 460;
  static const double tamanoGlobo = 100;

  /// Alto total de un globo con su hilo.
  static const double altoGlobo = tamanoGlobo * 1.12 + 34;

  final ActividadAtrapa actividad;

  const JuegoAtrapa({
    super.key,
    required this.actividad,
    required super.onResponder,
    required super.onCompletado,
    required super.random,
    required super.pausa,
  });

  @override
  State<JuegoAtrapa> createState() => _JuegoAtrapaState();
}

class _Globo {
  final int indice;

  /// Posición horizontal (0 a 1).
  final double x;

  /// Pixeles por segundo: despacio, para que los niños alcancen a tocarlos.
  final double velocidad;

  /// Altura inicial (0 abajo, 1 arriba).
  final double fase;
  final Color color;

  const _Globo({
    required this.indice,
    required this.x,
    required this.velocidad,
    required this.fase,
    required this.color,
  });
}

class _JuegoAtrapaState extends State<JuegoAtrapa>
    with SingleTickerProviderStateMixin, EstadoJuego<JuegoAtrapa> {
  // Colores vivos de globo de fiesta.
  static const List<Color> _colores = [
    Color(0xFFFF5C5C),
    Color(0xFF4FA3FF),
    Color(0xFFFFB627),
    Color(0xFF3CC47C),
    Color(0xFFA06CF5),
    Color(0xFFFF7EB6),
    Color(0xFFFF8A3D),
  ];

  late final Ticker _ticker;
  late final List<_Globo> _globos = _crearGlobos();
  final Set<int> _reventados = {};

  /// Dónde se reventó cada globo, para dibujar la explosión.
  final Map<int, Offset> _explosiones = {};

  /// Cuántas veces se tocó cada globo equivocado (para sacudirlo).
  final Map<int, int> _sacudidas = {};
  int? _fallido;
  Duration _tiempo = Duration.zero;

  List<ElementoAtrapa> get _elementos => widget.actividad.elementos;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((transcurrido) {
      setState(() => _tiempo = transcurrido);
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  List<_Globo> _crearGlobos() {
    final cantidad = _elementos.length;
    final orden = indicesMezclados(cantidad);
    const carriles = 3;

    return [
      for (var posicion = 0; posicion < cantidad; posicion++)
        _Globo(
          indice: orden[posicion],
          x: (posicion % carriles + 0.5) / carriles,
          velocidad: 28 + widget.random.nextDouble() * 18,
          // Repartidos a lo alto para que se vean varios desde el inicio.
          fase: 0.12 + (posicion / cantidad) * 0.76,
          color: _colores[posicion % _colores.length],
        ),
    ];
  }

  double get _segundos => _tiempo.inMicroseconds / 1e6;

  /// Distancia desde arriba de la zona, en pixeles.
  double _arriba(_Globo globo) {
    const recorrido = JuegoAtrapa.altoZona + JuegoAtrapa.altoGlobo;
    final subido =
        globo.fase * JuegoAtrapa.altoZona + globo.velocidad * _segundos;

    // Al salir por arriba vuelve a entrar por abajo.
    return JuegoAtrapa.altoZona - (subido % recorrido);
  }

  /// Se mecen un poco de lado a lado, como globos de verdad.
  double _izquierda(_Globo globo, double ancho) {
    final vaiven = sin(_segundos * 1.4 + globo.fase * 6) * 8;

    return globo.x * ancho - JuegoAtrapa.tamanoGlobo / 2 + vaiven;
  }

  void _tocar(_Globo globo, Offset centro) {
    if (_reventados.contains(globo.indice)) {
      return;
    }

    final elemento = _elementos[globo.indice];
    voz.hablar(elemento.elemento.paraLeer);

    setState(() {
      if (elemento.esCorrecto) {
        _reventados.add(globo.indice);
        _explosiones[globo.indice] = centro;
        _fallido = null;
      } else {
        _fallido = globo.indice;
        _sacudidas[globo.indice] = (_sacudidas[globo.indice] ?? 0) + 1;
      }
    });
    widget.onResponder(elemento.esCorrecto);

    if (elemento.esCorrecto &&
        _reventados.length == widget.actividad.totalAciertos) {
      _ticker.stop();
      despuesDeLaPausa(widget.onCompletado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final objetivo = widget.actividad.objetivo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IndicadorAvance(
          actual: _reventados.length,
          total: widget.actividad.totalAciertos,
        ),
        const SizedBox(height: 14),
        _Objetivo(emoji: objetivo.emoji, texto: objetivo.texto),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radio),
          child: SizedBox(
            height: JuegoAtrapa.altoZona,
            child: LayoutBuilder(
              builder: (context, limites) {
                return Stack(
                  children: [
                    const Positioned.fill(
                      child: CustomPaint(painter: _PintorCielo()),
                    ),
                    for (final globo in _globos)
                      if (!_reventados.contains(globo.indice))
                        _construirGlobo(globo, limites.maxWidth),
                    for (final MapEntry(key: indice, value: centro)
                        in _explosiones.entries)
                      Positioned(
                        left: centro.dx - _Explosion.tamano / 2,
                        top: centro.dy - _Explosion.tamano / 2,
                        child: _Explosion(
                          key: ValueKey('explosion-$indice'),
                          color: _globos
                              .firstWhere((globo) => globo.indice == indice)
                              .color,
                          onTerminar: () =>
                              setState(() => _explosiones.remove(indice)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirGlobo(_Globo globo, double ancho) {
    final izquierda = _izquierda(globo, ancho);
    final arriba = _arriba(globo);
    const centroGlobo = Offset(
      JuegoAtrapa.tamanoGlobo / 2,
      JuegoAtrapa.tamanoGlobo * 0.56,
    );

    return Positioned(
      left: izquierda,
      top: arriba,
      child: Sacudir(
        veces: _sacudidas[globo.indice] ?? 0,
        child: _GloboWidget(
          key: ValueKey('globo-${globo.indice}'),
          elemento: _elementos[globo.indice].elemento,
          color: globo.color,
          fallo: _fallido == globo.indice,
          onTap: () =>
              _tocar(globo, Offset(izquierda, arriba) + centroGlobo),
        ),
      ),
    );
  }
}

/// Qué globos hay que reventar, en grande.
class _Objetivo extends StatelessWidget {
  final String emoji;
  final String texto;

  const _Objetivo({required this.emoji, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.verde,
        borderRadius: BorderRadius.circular(AppTheme.radio),
        boxShadow: [
          BoxShadow(color: relieve(AppTheme.verde), offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Dibujo(emoji, tamano: 44),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Revienta: $texto',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const Dibujo('🎈', tamano: 42),
        ],
      ),
    );
  }
}

class _GloboWidget extends StatelessWidget {
  final ElementoVisual elemento;
  final Color color;
  final bool fallo;
  final VoidCallback onTap;

  const _GloboWidget({
    super.key,
    required this.elemento,
    required this.color,
    required this.fallo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const tamano = JuegoAtrapa.tamanoGlobo;

    return Semantics(
      button: true,
      label: elemento.texto,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: tamano,
          height: JuegoAtrapa.altoGlobo,
          child: CustomPaint(
            painter: _PintorGlobo(
              color: fallo ? const Color(0xFFB0B7C3) : color,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: tamano - 12,
                  height: tamano * 0.98,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Dibujo(elemento.emoji, tamano: 40),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          elemento.texto,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.texto,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Globo brillante con nudo e hilo ondulado.
class _PintorGlobo extends CustomPainter {
  final Color color;

  const _PintorGlobo({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final ancho = size.width;
    final cuerpo = Rect.fromLTWH(0, 0, ancho, ancho * 1.12);
    final abajo = Offset(ancho / 2, cuerpo.bottom);

    // Hilo.
    canvas.drawPath(
      Path()
        ..moveTo(abajo.dx, abajo.dy + 6)
        ..cubicTo(
          abajo.dx - 8,
          abajo.dy + 14,
          abajo.dx + 8,
          abajo.dy + 22,
          abajo.dx,
          size.height,
        ),
      Paint()
        ..color = const Color(0xFF6B7280)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Nudo.
    canvas.drawPath(
      Path()
        ..moveTo(abajo.dx - 6, abajo.dy + 7)
        ..lineTo(abajo.dx + 6, abajo.dy + 7)
        ..lineTo(abajo.dx, abajo.dy - 3)
        ..close(),
      Paint()..color = Color.lerp(color, Colors.black, 0.2)!,
    );

    // Cuerpo con luz arriba a la izquierda.
    canvas.drawOval(
      cuerpo,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.9,
          colors: [
            Color.lerp(color, Colors.white, 0.45)!,
            color,
            Color.lerp(color, Colors.black, 0.18)!,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(cuerpo),
    );

    // Brillo.
    canvas.save();
    canvas.translate(ancho * 0.28, ancho * 0.26);
    canvas.rotate(-0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: ancho * 0.16, height: ancho * 0.3),
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorGlobo anterior) => anterior.color != color;
}

/// Cielo con sol, nubes y pasto. Es estático: no gasta batería.
class _PintorCielo extends CustomPainter {
  const _PintorCielo();

  @override
  void paint(Canvas canvas, Size size) {
    final todo = Offset.zero & size;

    canvas.drawRect(
      todo,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7CC8FF), Color(0xFFD9F0FF)],
        ).createShader(todo),
    );

    // Sol con rayos.
    final sol = Offset(size.width - 46, 46);
    final rayo = Paint()
      ..color = const Color(0xFFFFD43B)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 10; i++) {
      final angulo = 2 * pi * i / 10;
      final direccion = Offset(cos(angulo), sin(angulo));
      canvas.drawLine(sol + direccion * 30, sol + direccion * 40, rayo);
    }
    canvas.drawCircle(sol, 24, Paint()..color = const Color(0xFFFFD43B));

    // Nubes.
    final nube = Paint()..color = Colors.white.withValues(alpha: 0.9);
    for (final (x, y, escala) in [
      (0.18, 0.12, 1.0),
      (0.62, 0.32, 0.8),
      (0.28, 0.55, 0.7),
    ]) {
      final centro = Offset(size.width * x, size.height * y);
      canvas.drawCircle(centro, 20 * escala, nube);
      canvas.drawCircle(centro + Offset(22 * escala, -8 * escala), 24 * escala, nube);
      canvas.drawCircle(centro + Offset(46 * escala, 0), 18 * escala, nube);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centro.dx - 8 * escala,
            centro.dy,
            70 * escala,
            20 * escala,
          ),
          Radius.circular(10 * escala),
        ),
        nube,
      );
    }

    // Colinas de pasto abajo.
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..lineTo(0, size.height - 30)
        ..quadraticBezierTo(
          size.width * 0.25,
          size.height - 60,
          size.width * 0.5,
          size.height - 32,
        )
        ..quadraticBezierTo(
          size.width * 0.75,
          size.height - 6,
          size.width,
          size.height - 40,
        )
        ..lineTo(size.width, size.height)
        ..close(),
      Paint()..color = const Color(0xFF7BD389),
    );
  }

  @override
  bool shouldRepaint(_PintorCielo anterior) => false;
}

/// El globo revienta: pedacitos de su color y estrellas que salen volando.
class _Explosion extends StatefulWidget {
  static const double tamano = 150;

  final Color color;
  final VoidCallback onTerminar;

  const _Explosion({super.key, required this.color, required this.onTerminar});

  @override
  State<_Explosion> createState() => _ExplosionState();
}

class _ExplosionState extends State<_Explosion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(() {
      if (mounted) {
        widget.onTerminar();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: _Explosion.tamano,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _PintorExplosion(_controller.value, widget.color),
          ),
        ),
      ),
    );
  }
}

class _PintorExplosion extends CustomPainter {
  final double t;
  final Color color;

  _PintorExplosion(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) {
      return;
    }

    final centro = size.center(Offset.zero);
    final avance = Curves.easeOut.transform(t);
    final opacidad = 1 - t;

    // Anillo que se abre.
    canvas.drawCircle(
      centro,
      12 + avance * size.width * 0.4,
      Paint()
        ..color = color.withValues(alpha: opacidad * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * (1 - t),
    );

    final pedazo = Paint()..color = color.withValues(alpha: opacidad);
    final estrella = Paint()
      ..color = const Color(0xFFFFC93C).withValues(alpha: opacidad);

    for (var i = 0; i < 10; i++) {
      final angulo = 2 * pi * i / 10;
      final direccion = Offset(cos(angulo), sin(angulo));

      if (i.isEven) {
        dibujarEstrella(
          canvas,
          centro + direccion * avance * size.width * 0.46,
          9,
          estrella,
        );
      } else {
        canvas.drawCircle(
          centro + direccion * avance * size.width * 0.36,
          6 * (1 - t * 0.5),
          pedazo,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PintorExplosion anterior) => anterior.t != t;
}
