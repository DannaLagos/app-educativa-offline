import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/boton_grande.dart';
import '../../domain/mascota.dart';
import 'mascota_animada.dart';

/// Pantalla completa que celebra cuando la mascota cambia de etapa: la forma
/// anterior brilla, un destello la transforma y aparece la nueva forma con
/// rayos de luz. Termina cuando el niño toca "¡Genial!".
class CeremoniaEvolucion extends StatefulWidget {
  static const Duration duracion = Duration(milliseconds: 2800);

  final MascotaElegida mascota;
  final EtapaMascota etapaAnterior;
  final EtapaMascota etapaNueva;
  final VoidCallback onTerminar;

  const CeremoniaEvolucion({
    super.key,
    required this.mascota,
    required this.etapaAnterior,
    required this.etapaNueva,
    required this.onTerminar,
  });

  /// Lo que se muestra y se lee en voz alta.
  static String anuncio(MascotaElegida mascota, EtapaMascota etapa) {
    return etapa == EtapaMascota.bebe
        ? '¡${mascota.nombre} nació!'
        : '¡${mascota.nombre} evolucionó a ${etapa.nombre}!';
  }

  @override
  State<CeremoniaEvolucion> createState() => _CeremoniaEvolucionState();
}

class _CeremoniaEvolucionState extends State<CeremoniaEvolucion>
    with SingleTickerProviderStateMixin {
  // Momentos de la animación (de 0 a 1).
  static const double _finBrillo = 0.45;
  static const double _finDestello = 0.55;
  static const double _apareceBoton = 0.8;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: CeremoniaEvolucion.duracion,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Sin animaciones (accesibilidad), se muestra directo la nueva forma.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else if (_controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF22A1570),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _construir(_controller.value),
        ),
      ),
    );
  }

  Widget _construir(double t) {
    final transformada = t >= _finDestello;
    final aparicion = transformada
        ? Curves.elasticOut.transform(
            ((t - _finDestello) / (1 - _finDestello)).clamp(0.0, 1.0),
          )
        : 0.0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PintorRayos(
                      giro: t,
                      intensidad: transformada ? aparicion.clamp(0.0, 1.0) : 0,
                    ),
                  ),
                ),
                if (transformada)
                  Transform.scale(
                    scale: 0.4 + 0.6 * aparicion,
                    child: _mascota(widget.etapaNueva, brillo: 0),
                  )
                else
                  _formaAnterior(t),
                // Destello blanco que tapa el cambio.
                IgnorePointer(
                  child: Opacity(
                    opacity: _opacidadDestello(t),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Colors.white, Color(0x00FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Opacity(
              opacity: transformada ? 1 : 0,
              child: _Titulo(
                texto: CeremoniaEvolucion.anuncio(
                  widget.mascota,
                  widget.etapaNueva,
                ),
                etapa: widget.etapaNueva,
              ),
            ),
          ),
          const Spacer(),
          Opacity(
            opacity: t >= _apareceBoton ? 1 : 0,
            child: BotonGrande(
              texto: '¡Genial!',
              icono: Icons.celebration_rounded,
              color: AppTheme.naranja,
              onPressed: t >= _apareceBoton ? widget.onTerminar : null,
            ),
          ),
        ],
      ),
    );
  }

  /// La forma anterior tiembla y se va llenando de luz.
  Widget _formaAnterior(double t) {
    final avance = (t / _finBrillo).clamp(0.0, 1.0);
    final temblor = sin(t * 90) * 6 * avance;

    return Transform.translate(
      offset: Offset(temblor, 0),
      child: Transform.scale(
        scale: 1 + 0.15 * avance,
        child: _mascota(widget.etapaAnterior, brillo: avance),
      ),
    );
  }

  Widget _mascota(EtapaMascota etapa, {required double brillo}) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.white.withValues(alpha: brillo * 0.9),
        BlendMode.srcATop,
      ),
      child: MascotaAnimada(
        especie: widget.mascota.especie,
        etapa: etapa,
        tamano: 200,
        animada: false,
        saltaAlTocar: false,
      ),
    );
  }

  /// Un halo que crece mientras brilla, el destello que tapa el cambio y
  /// luego se apaga.
  static double _opacidadDestello(double t) {
    if (t < _finBrillo - 0.1) {
      return 0.45 * t / (_finBrillo - 0.1);
    }
    if (t < _finDestello) {
      return (0.45 + (t - (_finBrillo - 0.1)) / 0.2).clamp(0.0, 1.0);
    }
    return (1 - (t - _finDestello) / 0.15).clamp(0.0, 1.0);
  }
}

class _Titulo extends StatelessWidget {
  final String texto;
  final EtapaMascota etapa;

  const _Titulo({required this.texto, required this.etapa});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.amarillo,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '✨ Etapa: ${etapa.nombre} ✨',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF5C3A00),
            ),
          ),
        ),
      ],
    );
  }
}

/// Rayos de luz que giran detrás de la nueva forma, con chispitas.
class _PintorRayos extends CustomPainter {
  static const int _rayos = 12;

  final double giro;
  final double intensidad;

  const _PintorRayos({required this.giro, required this.intensidad});

  @override
  void paint(Canvas canvas, Size size) {
    if (intensidad <= 0) {
      return;
    }

    final centro = size.center(Offset.zero);
    final radio = size.shortestSide * 0.75;
    // Los rayos se desvanecen hacia afuera para no tapar el título.
    final rayo = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.amarillo.withValues(alpha: 0.45 * intensidad),
          AppTheme.amarillo.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: centro, radius: radio));

    for (var i = 0; i < _rayos; i++) {
      final angulo = giro * pi + i * 2 * pi / _rayos;
      final camino = Path()
        ..moveTo(centro.dx, centro.dy)
        ..lineTo(
          centro.dx + cos(angulo - 0.12) * radio,
          centro.dy + sin(angulo - 0.12) * radio,
        )
        ..lineTo(
          centro.dx + cos(angulo + 0.12) * radio,
          centro.dy + sin(angulo + 0.12) * radio,
        )
        ..close();
      canvas.drawPath(camino, rayo);
    }

    final chispa = Paint()
      ..color = Colors.white.withValues(alpha: 0.85 * intensidad);
    final azar = Random(5);

    for (var i = 0; i < 18; i++) {
      final angulo = azar.nextDouble() * 2 * pi + giro * 2;
      final distancia = radio * (0.35 + 0.55 * azar.nextDouble());
      canvas.drawCircle(
        centro + Offset(cos(angulo), sin(angulo)) * distancia,
        2 + 3 * azar.nextDouble(),
        chispa,
      );
    }
  }

  @override
  bool shouldRepaint(_PintorRayos anterior) =>
      anterior.giro != giro || anterior.intensidad != intensidad;
}
