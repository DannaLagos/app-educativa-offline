import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/actividad.dart';
import '../widgets/tarjeta_elemento.dart';
import 'juego_base.dart';

/// Memoria: las cartas están boca abajo; el niño voltea dos y, si son
/// pareja, se quedan descubiertas.
///
/// Fallar al principio es normal (todavía no sabe dónde están), así que solo
/// cuenta como error cuando la pareja de una carta ya se había visto antes.
class JuegoMemoria extends JuegoBase {
  final ActividadMemoria actividad;

  const JuegoMemoria({
    super.key,
    required this.actividad,
    required super.onResponder,
    required super.onCompletado,
    required super.random,
    required super.pausa,
  });

  @override
  State<JuegoMemoria> createState() => _JuegoMemoriaState();
}

/// Una carta: a qué pareja pertenece y de qué lado es.
typedef _Carta = ({int pareja, int lado});

class _JuegoMemoriaState extends State<JuegoMemoria>
    with EstadoJuego<JuegoMemoria> {
  late final List<_Carta> _cartas = _mezclarCartas();
  final Set<int> _encontradas = {};
  final Set<_Carta> _vistas = {};
  final List<_Carta> _volteadas = [];
  bool _esperando = false;

  List<_Carta> _mezclarCartas() {
    final cartas = <_Carta>[
      for (var i = 0; i < widget.actividad.pares.length; i++) ...[
        (pareja: i, lado: 0),
        (pareja: i, lado: 1),
      ],
    ];

    return cartas..shuffle(widget.random);
  }

  ElementoVisual _elemento(_Carta carta) {
    final pareja = widget.actividad.pares[carta.pareja];

    return carta.lado == 0 ? pareja.izquierda : pareja.derecha;
  }

  bool _estaBocaArriba(_Carta carta) =>
      _encontradas.contains(carta.pareja) || _volteadas.contains(carta);

  void _voltear(_Carta carta) {
    if (_esperando || _estaBocaArriba(carta)) {
      return;
    }

    voz.hablar(_elemento(carta).texto);
    setState(() => _volteadas.add(carta));

    if (_volteadas.length == 2) {
      _comparar();
    }
  }

  void _comparar() {
    final primera = _volteadas[0];
    final segunda = _volteadas[1];

    if (primera.pareja == segunda.pareja) {
      setState(() {
        _encontradas.add(primera.pareja);
        _volteadas.clear();
      });
      widget.onResponder(true);

      if (_encontradas.length == widget.actividad.pares.length) {
        despuesDeLaPausa(widget.onCompletado);
      }
      return;
    }

    // Error de memoria: ya había visto dónde estaba la pareja de alguna.
    final yaSabia = _vistas.contains(_companera(primera)) ||
        _vistas.contains(_companera(segunda));

    _vistas
      ..add(primera)
      ..add(segunda);

    if (yaSabia) {
      widget.onResponder(false);
    }

    // Se dejan un momento a la vista para que el niño las recuerde.
    _esperando = true;
    Future<void>.delayed(widget.pausa * 1.5, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _volteadas.clear();
        _esperando = false;
      });
    });
  }

  static _Carta _companera(_Carta carta) =>
      (pareja: carta.pareja, lado: 1 - carta.lado);

  @override
  Widget build(BuildContext context) {
    final columnas = _cartas.length <= 6 ? 3 : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IndicadorAvance(
          actual: _encontradas.length,
          total: widget.actividad.pares.length,
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: columnas,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.8,
          children: [
            for (final carta in _cartas)
              _CartaMemoria(
                key: ValueKey('carta-${carta.pareja}-${carta.lado}'),
                elemento: _elemento(carta),
                bocaArriba: _estaBocaArriba(carta),
                encontrada: _encontradas.contains(carta.pareja),
                onTap: () => _voltear(carta),
              ),
          ],
        ),
      ],
    );
  }
}

class _CartaMemoria extends StatelessWidget {
  final ElementoVisual elemento;
  final bool bocaArriba;
  final bool encontrada;
  final VoidCallback onTap;

  const _CartaMemoria({
    super.key,
    required this.elemento,
    required this.bocaArriba,
    required this.encontrada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: bocaArriba ? elemento.texto : 'Carta boca abajo',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: bocaArriba ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, giro, _) {
            // Gira sobre el eje vertical; a mitad de giro cambia la cara.
            final mostrarFrente = giro >= 0.5;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(math.pi * giro),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateY(mostrarFrente ? math.pi : 0),
                child: mostrarFrente ? _frente() : _reverso(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _reverso() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.azul,
        borderRadius: BorderRadius.circular(AppTheme.radio),
        border: Border.all(color: AppTheme.azulClaro, width: 3),
      ),
      alignment: Alignment.center,
      child: const Text('⭐', style: TextStyle(fontSize: 36)),
    );
  }

  Widget _frente() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: encontrada ? AppTheme.verdeSuave : AppTheme.superficie,
        borderRadius: BorderRadius.circular(AppTheme.radio),
        border: Border.all(
          color: encontrada ? AppTheme.verde : AppTheme.azul,
          width: 3,
        ),
      ),
      // La carta tiene tamaño fijo (cuadrícula): si el texto no cabe, todo
      // se reduce en vez de desbordarse.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(elemento.emoji, style: const TextStyle(fontSize: 38)),
              const SizedBox(height: 4),
              Text(
                elemento.texto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
