import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/mascota.dart';
import '../apariencia_mascota.dart';

/// Cómo se siente la mascota (además de la alegría del salto).
enum ExpresionMascota {
  normal,

  /// Cejitas preocupadas y una gotita: anima al niño cuando se equivoca.
  animo,

  /// Ojos cerrados y "z z z": el niño lleva días sin jugar.
  dormida,
}

/// Dibuja la mascota en su etapa. Si está [animada] respira, rebota y
/// parpadea, y salta cuando el niño la toca. Respeta la opción del teléfono
/// de reducir animaciones.
class MascotaAnimada extends StatefulWidget {
  final EspecieMascota especie;
  final EtapaMascota etapa;
  final double tamano;
  final bool animada;

  /// false cuando la mascota está dentro de otro botón (como en el selector).
  final bool saltaAlTocar;

  /// De 0 a 1: para que varias mascotas juntas no reboten al mismo tiempo.
  final double desfase;

  /// Cada vez que aumenta, la mascota salta de alegría (por ejemplo, con
  /// cada acierto en un juego).
  final int saltos;

  final ExpresionMascota expresion;

  /// Se llama cuando el niño la toca (además del salto).
  final VoidCallback? onTocar;

  const MascotaAnimada({
    super.key,
    required this.especie,
    required this.etapa,
    this.tamano = 120,
    this.animada = true,
    this.saltaAlTocar = true,
    this.desfase = 0,
    this.saltos = 0,
    this.expresion = ExpresionMascota.normal,
    this.onTocar,
  });

  @override
  State<MascotaAnimada> createState() => _MascotaAnimadaState();
}

class _MascotaAnimadaState extends State<MascotaAnimada>
    with TickerProviderStateMixin {
  late final AnimationController _vaiven = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
    value: widget.desfase,
  );
  late final AnimationController _salto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  bool get _puedeMoverse =>
      widget.animada &&
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _actualizarVaiven();
  }

  @override
  void didUpdateWidget(MascotaAnimada anterior) {
    super.didUpdateWidget(anterior);
    _actualizarVaiven();

    // Al elegirla o al evolucionar, salta de alegría.
    if ((!anterior.animada && widget.animada) ||
        anterior.etapa != widget.etapa ||
        widget.saltos > anterior.saltos) {
      _saltar();
    }
  }

  @override
  void dispose() {
    _vaiven.dispose();
    _salto.dispose();
    super.dispose();
  }

  void _actualizarVaiven() {
    if (_puedeMoverse && !_vaiven.isAnimating) {
      _vaiven.repeat();
    } else if (!_puedeMoverse && _vaiven.isAnimating) {
      _vaiven.stop();
    }
  }

  void _saltar() {
    if (_puedeMoverse) {
      _salto.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dibujo = SizedBox.square(
      dimension: widget.tamano,
      child: AnimatedBuilder(
        animation: Listenable.merge([_vaiven, _salto]),
        builder: (context, _) => CustomPaint(
          painter: _PintorMascota(
            apariencia: AparienciaMascota.de(widget.especie),
            especie: widget.especie,
            etapa: widget.etapa,
            tiempo: _vaiven.value,
            salto: _salto.value,
            expresion: widget.expresion,
          ),
        ),
      ),
    );

    return Semantics(
      image: true,
      label: '${widget.especie.nombre}, etapa ${widget.etapa.nombre}',
      child: widget.saltaAlTocar
          ? GestureDetector(
              onTap: () {
                _saltar();
                widget.onTocar?.call();
              },
              child: dibujo,
            )
          : dibujo,
    );
  }
}

/// Dibuja en una cuadrícula de 100 × 100 que se escala al tamaño real.
class _PintorMascota extends CustomPainter {
  static const Color _ojos = Color(0xFF2B2140);
  static const Color _mejillas = Color(0x66FF6F91);
  static const Color _destello = Color(0xFFFFD84D);

  final AparienciaMascota apariencia;
  final EspecieMascota especie;
  final EtapaMascota etapa;

  /// De 0 a 1, se repite: respiración, rebote y parpadeo.
  final double tiempo;

  /// De 0 a 1 mientras salta.
  final double salto;

  final ExpresionMascota expresion;

  _PintorMascota({
    required this.apariencia,
    required this.especie,
    required this.etapa,
    required this.tiempo,
    required this.salto,
    required this.expresion,
  });

  /// Tonos para dar volumen: luz arriba a la izquierda, sombra abajo.
  Color get _luz => Color.lerp(apariencia.principal, Colors.white, 0.38)!;
  Color get _sombraCuerpo =>
      Color.lerp(apariencia.principal, Colors.black, 0.2)!;

  /// Lo que va detrás del cuerpo, un poco más oscuro: se siente profundidad.
  Color get _principalAtras =>
      Color.lerp(apariencia.principal, Colors.black, 0.1)!;

  double get _onda => sin(2 * pi * tiempo);

  double get _altura => 1.5 * (_onda + 1) + 14 * sin(pi * salto);

  bool get _estaFeliz => salto > 0 && salto < 1;

  bool get _parpadea => tiempo > 0.47 && tiempo < 0.52;

  bool get _duerme => expresion == ExpresionMascota.dormida && !_estaFeliz;

  /// Las accesorios (cuernos, orejas, hojas...) crecen con cada etapa.
  double get _crecimiento => switch (etapa) {
        EtapaMascota.huevo || EtapaMascota.bebe => 0.8,
        EtapaMascota.exploradora => 1.0,
        EtapaMascota.leyenda => 1.15,
      };

  double get _escala => switch (etapa) {
        EtapaMascota.huevo || EtapaMascota.bebe => 0.78,
        EtapaMascota.exploradora => 0.9,
        EtapaMascota.leyenda => 1.0,
      };

  Paint _relleno(Color color) => Paint()..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    _sombra(canvas);

    if (etapa == EtapaMascota.huevo) {
      _huevo(canvas);
      return;
    }

    final respiracion = 0.025 * _onda;

    canvas.save();
    // Se escala desde los pies, así la mascota crece hacia arriba.
    canvas.translate(50, 90 - _altura);
    canvas.scale(_escala * (1 + respiracion), _escala * (1 - respiracion));
    canvas.translate(-50, -90);

    if (etapa == EtapaMascota.leyenda) {
      _aura(canvas);
    }
    _detrasDelCuerpo(canvas);
    _cuerpo(canvas);
    if (etapa.index >= EtapaMascota.exploradora.index) {
      _marcas(canvas);
    }
    _cara(canvas);
    _encimaDelCuerpo(canvas);
    if (_duerme) {
      _zetas(canvas, const Offset(72, 24));
    }
    canvas.restore();

    if (etapa == EtapaMascota.leyenda) {
      _destellos(canvas);
    }
  }

  void _sombra(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: const Offset(50, 93),
      width: 50 - _altura * 1.2,
      height: 8,
    );
    // Sombra difuminada: más oscura en el centro.
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0x2E000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
  }

  void _huevo(Canvas canvas) {
    canvas.save();
    // Se tambalea como si algo se moviera adentro.
    canvas.translate(50, 90);
    canvas.rotate(0.08 * _onda + 0.15 * sin(2 * pi * salto));
    canvas.translate(-50, -90 + sin(pi * salto) * -6);

    final cascara = Path()
      ..moveTo(50, 22)
      ..cubicTo(68, 22, 78, 50, 78, 64)
      ..cubicTo(78, 80, 66, 90, 50, 90)
      ..cubicTo(34, 90, 22, 80, 22, 64)
      ..cubicTo(22, 50, 32, 22, 50, 22)
      ..close();
    final limites = cascara.getBounds();

    canvas.drawPath(
      cascara,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.0,
          colors: [
            Color.lerp(apariencia.claro, Colors.white, 0.4)!,
            apariencia.principal,
            _sombraCuerpo,
          ],
          stops: const [0, 0.6, 1],
        ).createShader(limites),
    );

    canvas.save();
    canvas.clipPath(cascara);
    final manchas = _relleno(apariencia.acento.withValues(alpha: 0.8));
    canvas.drawCircle(const Offset(38, 46), 6, manchas);
    canvas.drawCircle(const Offset(62, 60), 7, manchas);
    canvas.drawCircle(const Offset(42, 76), 5, manchas);
    canvas.drawCircle(const Offset(70, 40), 4, manchas);
    canvas.restore();

    // Brillo de cáscara lisa.
    canvas.drawOval(
      const Rect.fromLTWH(33, 31, 9, 16),
      _relleno(Colors.white.withValues(alpha: 0.65)),
    );
    canvas.drawCircle(const Offset(44, 52), 1.8, _relleno(Colors.white70));
    if (_duerme) {
      _zetas(canvas, const Offset(70, 26));
    }
    canvas.restore();
  }

  void _aura(Canvas canvas) {
    const centro = Offset(50, 58);
    canvas.drawCircle(
      centro,
      48,
      Paint()
        ..shader = RadialGradient(
          colors: [
            apariencia.acento.withValues(alpha: 0.45 + 0.1 * _onda),
            apariencia.acento.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: 48)),
    );
  }

  void _cuerpo(Canvas canvas) {
    for (final x in const [38.0, 62.0]) {
      final pie = Rect.fromCenter(center: Offset(x, 87), width: 17, height: 10);
      canvas.drawOval(
        pie,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [apariencia.principal, _sombraCuerpo],
          ).createShader(pie),
      );
    }

    // Cuerpo con volumen: luz arriba a la izquierda, sombra abajo.
    final cuerpo =
        Rect.fromCenter(center: const Offset(50, 58), width: 62, height: 60);
    canvas.drawOval(
      cuerpo,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.45),
          radius: 0.95,
          colors: [_luz, apariencia.principal, _sombraCuerpo],
          stops: const [0, 0.55, 1],
        ).createShader(cuerpo),
    );

    // Panza suave.
    final panza =
        Rect.fromCenter(center: const Offset(50, 71), width: 36, height: 26);
    canvas.drawOval(
      panza,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.3),
          colors: [
            Color.lerp(apariencia.claro, Colors.white, 0.35)!,
            apariencia.claro,
          ],
        ).createShader(panza),
    );

    // Reflejo de luz en la cabeza.
    canvas.save();
    canvas.translate(36, 37);
    canvas.rotate(-0.55);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 15, height: 7),
      _relleno(Colors.white.withValues(alpha: 0.35)),
    );
    canvas.restore();
  }

  void _marcas(Canvas canvas) {
    final marca = _relleno(apariencia.acento.withValues(alpha: 0.55));
    canvas.drawCircle(const Offset(25, 64), 3, marca);
    canvas.drawCircle(const Offset(28, 72), 2.2, marca);
    canvas.drawCircle(const Offset(75, 64), 3, marca);
    canvas.drawCircle(const Offset(72, 72), 2.2, marca);
  }

  void _cara(Canvas canvas) {
    final trazo = Paint()
      ..color = _ojos
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (final x in const [40.0, 60.0]) {
      if (_estaFeliz) {
        // Ojos felices: ^ ^
        canvas.drawPath(
          Path()
            ..moveTo(x - 5, 54)
            ..quadraticBezierTo(x, 46, x + 5, 54),
          trazo,
        );
      } else if (_duerme) {
        // Ojos cerrados de dormir: ∪
        canvas.drawPath(
          Path()
            ..moveTo(x - 5, 51)
            ..quadraticBezierTo(x, 56, x + 5, 51),
          trazo,
        );
      } else if (_parpadea) {
        canvas.drawLine(Offset(x - 5, 52), Offset(x + 5, 52), trazo);
      } else {
        _ojoAbierto(canvas, x);
      }
    }

    if (expresion == ExpresionMascota.animo && !_estaFeliz) {
      _cejasDeAnimo(canvas, trazo);
    }

    // Mejillas difuminadas.
    for (final x in const [30.0, 70.0]) {
      final mejilla = Rect.fromCircle(center: Offset(x, 62), radius: 6);
      canvas.drawOval(
        mejilla,
        Paint()
          ..shader = const RadialGradient(
            colors: [_mejillas, Color(0x00FF6F91)],
          ).createShader(mejilla),
      );
    }

    if (_estaFeliz) {
      // Boca abierta con lengüita.
      final boca = Path()
        ..moveTo(44, 61)
        ..quadraticBezierTo(50, 72, 56, 61)
        ..close();
      canvas.drawPath(boca, _relleno(_ojos));
      canvas.save();
      canvas.clipPath(boca);
      canvas.drawCircle(
          const Offset(50, 69), 4, _relleno(const Color(0xFFFF8FA3)));
      canvas.restore();
    } else if (_duerme) {
      canvas.drawCircle(const Offset(50, 64), 1.8, _relleno(_ojos));
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(45, 62)
          ..quadraticBezierTo(50, 67, 55, 62),
        trazo,
      );
    }

    if (expresion == ExpresionMascota.animo && !_estaFeliz) {
      _gotita(canvas);
    }
  }

  /// Ojo grande: blanco con sombrita, iris de color, pupila y dos brillos.
  void _ojoAbierto(Canvas canvas, double x) {
    final blanco =
        Rect.fromCenter(center: Offset(x, 52), width: 14, height: 16);
    canvas.drawOval(
      blanco,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFE6E2F0)],
        ).createShader(blanco),
    );

    final iris = Rect.fromCircle(center: Offset(x + 1, 53.5), radius: 5);
    canvas.drawOval(
      iris,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.4),
          colors: [
            Color.lerp(apariencia.principal, Colors.black, 0.25)!,
            Color.lerp(apariencia.principal, Colors.black, 0.6)!,
          ],
        ).createShader(iris),
    );
    canvas.drawCircle(Offset(x + 1, 53.5), 2.6, _relleno(_ojos));
    canvas.drawCircle(Offset(x + 2.8, 50.8), 1.9, _relleno(Colors.white));
    canvas.drawCircle(Offset(x - 0.8, 55.6), 0.9, _relleno(Colors.white70));
  }

  /// Cejitas inclinadas hacia el centro: "¡tú puedes, inténtalo otra vez!".
  void _cejasDeAnimo(Canvas canvas, Paint trazo) {
    final ceja = Paint()
      ..color = trazo.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(35, 42), const Offset(43, 40), ceja);
    canvas.drawLine(const Offset(65, 42), const Offset(57, 40), ceja);
  }

  /// Gotita de sudor al lado de la cabeza.
  void _gotita(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(76, 38)
        ..quadraticBezierTo(71, 46, 76, 48)
        ..quadraticBezierTo(81, 46, 76, 38)
        ..close(),
      _relleno(const Color(0xFF7CC8FF)),
    );
    canvas.drawCircle(const Offset(75, 45), 1, _relleno(Colors.white));
  }

  /// "z z z" que suben despacio cuando duerme.
  void _zetas(Canvas canvas, Offset base) {
    for (var i = 0; i < 3; i++) {
      final avance = (tiempo + i / 3) % 1;
      final pintor = TextPainter(
        text: TextSpan(
          text: 'z',
          style: TextStyle(
            fontSize: 7 + i * 2.0,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF6741D9).withValues(alpha: 1 - avance),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      pintor.paint(canvas, base + Offset(i * 5.0, -avance * 14 - i * 4));
    }
  }

  void _detrasDelCuerpo(Canvas canvas) {
    final f = _crecimiento;

    switch (especie) {
      case EspecieMascota.chispa:
        // Cola con punta y, desde exploradora, alitas.
        canvas.drawPath(
          Path()
            ..moveTo(70, 80)
            ..quadraticBezierTo(86, 80, 90, 66 - 4 * f)
            ..lineTo(80, 72)
            ..quadraticBezierTo(76, 76, 68, 74)
            ..close(),
          _relleno(_principalAtras),
        );
        canvas.drawPath(
          Path()
            ..moveTo(90, 66 - 4 * f)
            ..lineTo(84, 64)
            ..lineTo(88, 74)
            ..close(),
          _relleno(apariencia.acento),
        );
        if (etapa.index >= EtapaMascota.exploradora.index) {
          final ala = _relleno(apariencia.acento.withValues(alpha: 0.85));
          for (final lado in const [-1.0, 1.0]) {
            canvas.drawPath(
              Path()
                ..moveTo(50 + lado * 24, 50)
                ..lineTo(50 + lado * (34 + 8 * f), 34)
                ..lineTo(50 + lado * (36 + 6 * f), 52)
                ..lineTo(50 + lado * 26, 60)
                ..close(),
              ala,
            );
          }
        }
      case EspecieMascota.burbu:
        // Branquias rosadas a los lados de la cabeza.
        final branquia = Paint()
          ..color = apariencia.acento
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        for (final lado in const [-1.0, 1.0]) {
          for (final angulo in const [-0.6, -0.15, 0.3]) {
            final inicio = Offset(50 + lado * 26, 46);
            final fin = inicio +
                Offset(
                  lado * cos(angulo) * 13 * f,
                  sin(angulo) * 13 * f,
                );
            canvas.drawLine(inicio, fin, branquia);
          }
        }
      case EspecieMascota.lumi:
        // Orejas puntiagudas y cola esponjosa.
        for (final lado in const [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(50 + lado * 6, 32)
              ..lineTo(50 + lado * 20, 30 - 18 * f)
              ..lineTo(50 + lado * 28, 42)
              ..close(),
            _relleno(_principalAtras),
          );
          canvas.drawPath(
            Path()
              ..moveTo(50 + lado * 11, 32)
              ..lineTo(50 + lado * 20, 33 - 13 * f)
              ..lineTo(50 + lado * 24, 38)
              ..close(),
            _relleno(apariencia.claro),
          );
        }
        canvas.save();
        canvas.translate(78, 70);
        canvas.rotate(-0.6 + 0.1 * _onda);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 14 * f, height: 30 * f),
          _relleno(_principalAtras),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, -10 * f),
            width: 10 * f,
            height: 11 * f,
          ),
          _relleno(apariencia.claro),
        );
        canvas.restore();
      case EspecieMascota.brote:
        // Tallo con hojas; crece con cada etapa.
        final tallo = Paint()
          ..color = const Color(0xFF3E9B35)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        final punta = Offset(50, 30 - 12 * f);
        canvas.drawLine(const Offset(50, 32), punta, tallo);
        final hoja = _relleno(const Color(0xFF4CBF3F));
        for (final lado in const [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(50, 30 - 6 * f);
          canvas.rotate(lado * (0.9 + 0.08 * _onda));
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(0, -8 * f),
              width: 9 * f,
              height: 17 * f,
            ),
            hoja,
          );
          canvas.restore();
        }
      case EspecieMascota.nimbo:
        // Bolitas de nube alrededor de la cabeza.
        final bolitas = [
          (const Offset(30, 40), 11 * f),
          (Offset(50, 32 - 2 * f), 14 * f),
          (const Offset(70, 40), 11 * f),
          (const Offset(22, 60), 9 * f),
          (const Offset(78, 60), 9 * f),
        ];
        for (final (centro, radio) in bolitas) {
          canvas.drawCircle(centro, radio, _relleno(_principalAtras));
        }
    }
  }

  void _encimaDelCuerpo(Canvas canvas) {
    final f = _crecimiento;

    switch (especie) {
      case EspecieMascota.chispa:
        for (final lado in const [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(50 + lado * 8, 31)
              ..lineTo(50 + lado * 15, 30 - 12 * f)
              ..lineTo(50 + lado * 20, 34)
              ..close(),
            _relleno(apariencia.claro),
          );
        }
      case EspecieMascota.burbu:
        // Burbujas que suben.
        final burbuja = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        final subida = (tiempo * 18) % 18;
        canvas.drawCircle(Offset(80, 40 - subida), 3 * f, burbuja);
        canvas.drawCircle(Offset(86, 28 - subida / 2), 2 * f, burbuja);
      case EspecieMascota.lumi:
        _estrella(
          canvas,
          const Offset(50, 39),
          5 * f,
          _relleno(apariencia.acento),
          puntas: 5,
        );
      case EspecieMascota.brote:
        if (etapa.index >= EtapaMascota.exploradora.index) {
          _flor(canvas, Offset(50, 28 - 12 * f), f);
        }
      case EspecieMascota.nimbo:
        _rayo(canvas, const Offset(76, 22), f);
        if (etapa.index >= EtapaMascota.exploradora.index) {
          _rayo(canvas, const Offset(20, 26), f * 0.8);
        }
    }
  }

  void _flor(Canvas canvas, Offset centro, double f) {
    final petalo = _relleno(apariencia.acento);
    final abierta = etapa == EtapaMascota.leyenda;
    final petalos = abierta ? 6 : 3;

    for (var i = 0; i < petalos; i++) {
      final angulo = 2 * pi * i / petalos + tiempo * 0.5;
      canvas.drawCircle(
        centro + Offset(cos(angulo), sin(angulo)) * 4.5 * f,
        (abierta ? 4 : 3) * f,
        petalo,
      );
    }
    canvas.drawCircle(centro, 3 * f, _relleno(const Color(0xFFFFD43B)));
  }

  void _rayo(Canvas canvas, Offset origen, double f) {
    canvas.save();
    canvas.translate(origen.dx, origen.dy);
    canvas.scale(f);
    canvas.drawPath(
      Path()
        ..moveTo(2, -10)
        ..lineTo(-5, 1)
        ..lineTo(0, 1)
        ..lineTo(-3, 11)
        ..lineTo(6, -2)
        ..lineTo(1, -2)
        ..close(),
      _relleno(apariencia.acento),
    );
    canvas.restore();
  }

  void _destellos(Canvas canvas) {
    final destello = _relleno(_destello);

    for (var i = 0; i < 4; i++) {
      final angulo = 2 * pi * (tiempo + i / 4);
      final centro =
          const Offset(50, 54) + Offset(cos(angulo), sin(angulo)) * 44;
      _estrella(canvas, centro, 3.5 + _onda.abs(), destello, puntas: 4);
    }
  }

  void _estrella(
    Canvas canvas,
    Offset centro,
    double radio,
    Paint pintura, {
    required int puntas,
  }) {
    final camino = Path();

    for (var i = 0; i < puntas * 2; i++) {
      final r = i.isEven ? radio : radio * 0.45;
      final angulo = -pi / 2 + pi * i / puntas;
      final punto = centro + Offset(cos(angulo), sin(angulo)) * r;
      i == 0
          ? camino.moveTo(punto.dx, punto.dy)
          : camino.lineTo(punto.dx, punto.dy);
    }

    canvas.drawPath(camino..close(), pintura);
  }

  @override
  bool shouldRepaint(_PintorMascota anterior) {
    return anterior.tiempo != tiempo ||
        anterior.salto != salto ||
        anterior.etapa != etapa ||
        anterior.especie != especie ||
        anterior.expresion != expresion;
  }
}
