import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/actividad.dart';
import '../widgets/tarjeta_elemento.dart';
import 'juego_base.dart';

/// Atrapa: los dibujos suben despacio como globos y el niño revienta solo
/// los que cumplen el objetivo. Los globos que se escapan vuelven a salir
/// por abajo, así que nadie pierde por ser lento.
class JuegoAtrapa extends JuegoBase {
  /// Alto de la zona donde suben los globos.
  static const double altoZona = 440;
  static const double tamanoGlobo = 96;

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
  static const List<Color> _colores = [
    Color(0xFFFFC9C9),
    Color(0xFFC9E7FF),
    Color(0xFFD7F5C9),
    Color(0xFFFFE9B3),
    Color(0xFFE8D4FF),
  ];

  late final Ticker _ticker;
  late final List<_Globo> _globos = _crearGlobos();
  final Set<int> _reventados = {};
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

  /// Distancia desde arriba de la zona, en pixeles.
  double _arriba(_Globo globo) {
    const recorrido = JuegoAtrapa.altoZona + JuegoAtrapa.tamanoGlobo;
    final subido = globo.fase * JuegoAtrapa.altoZona +
        globo.velocidad * _tiempo.inMicroseconds / 1e6;

    // Al salir por arriba vuelve a entrar por abajo.
    return JuegoAtrapa.altoZona - (subido % recorrido);
  }

  void _tocar(_Globo globo) {
    if (_reventados.contains(globo.indice)) {
      return;
    }

    final elemento = _elementos[globo.indice];
    voz.hablar(elemento.elemento.texto);

    setState(() {
      if (elemento.esCorrecto) {
        _reventados.add(globo.indice);
        _fallido = null;
      } else {
        _fallido = globo.indice;
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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.verdeSuave,
            borderRadius: BorderRadius.circular(AppTheme.radio),
            border: Border.all(color: AppTheme.verde, width: 2),
          ),
          child: Row(
            children: [
              Text(objetivo.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Revienta: ${objetivo.texto}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.verde,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radio),
          child: Container(
            height: JuegoAtrapa.altoZona,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFBFE3FF), Color(0xFFEAF5FD)],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, limites) {
                return Stack(
                  children: [
                    for (final globo in _globos)
                      if (!_reventados.contains(globo.indice))
                        Positioned(
                          left: globo.x * limites.maxWidth -
                              JuegoAtrapa.tamanoGlobo / 2,
                          top: _arriba(globo),
                          child: _GloboWidget(
                            key: ValueKey('globo-${globo.indice}'),
                            elemento: _elementos[globo.indice].elemento,
                            color: globo.color,
                            fallo: _fallido == globo.indice,
                            onTap: () => _tocar(globo),
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
          height: tamano + 14,
          child: Column(
            children: [
              Container(
                width: tamano,
                height: tamano,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fallo ? AppTheme.ambarSuave : color,
                  border: Border.all(
                    color: fallo ? AppTheme.ambar : Colors.white,
                    width: 3,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(elemento.emoji, style: const TextStyle(fontSize: 36)),
                    Container(
                      width: tamano - 12,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        elemento.texto,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.texto,
                        ),
                      ),
                    ),
                  ],
                  ),
                ),
              ),
              // El hilo del globo.
              Container(width: 2, height: 14, color: AppTheme.textoSecundario),
            ],
          ),
        ),
      ),
    );
  }
}
