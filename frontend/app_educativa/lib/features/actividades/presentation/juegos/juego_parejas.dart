import 'package:flutter/material.dart';

import '../../domain/actividad.dart';
import '../widgets/tarjeta_elemento.dart';
import 'juego_base.dart';

/// Parejas: tocar un elemento de un lado y luego su pareja del otro lado.
class JuegoParejas extends JuegoBase {
  final ActividadParejas actividad;

  const JuegoParejas({
    super.key,
    required this.actividad,
    required super.onResponder,
    required super.onCompletado,
    required super.random,
    required super.pausa,
  });

  @override
  State<JuegoParejas> createState() => _JuegoParejasState();
}

class _JuegoParejasState extends State<JuegoParejas>
    with EstadoJuego<JuegoParejas> {
  late final List<int> _ordenDerecha =
      indicesMezclados(widget.actividad.pares.length);
  final Set<int> _unidas = {};
  int? _izquierda;
  int? _derecha;

  /// Par que se acaba de intentar sin éxito (se muestra un momento).
  (int, int)? _fallo;

  List<Pareja> get _pares => widget.actividad.pares;

  void _tocarIzquierda(int indice) {
    voz.hablar(_pares[indice].izquierda.texto);
    setState(() {
      _fallo = null;
      _izquierda = indice;
    });
    _comprobar();
  }

  void _tocarDerecha(int indice) {
    voz.hablar(_pares[indice].derecha.texto);
    setState(() {
      _fallo = null;
      _derecha = indice;
    });
    _comprobar();
  }

  void _comprobar() {
    final izquierda = _izquierda;
    final derecha = _derecha;

    if (izquierda == null || derecha == null) {
      return;
    }

    final esPareja = izquierda == derecha;

    setState(() {
      if (esPareja) {
        _unidas.add(izquierda);
      } else {
        _fallo = (izquierda, derecha);
      }
      _izquierda = null;
      _derecha = null;
    });
    widget.onResponder(esPareja);

    if (esPareja && _unidas.length == _pares.length) {
      despuesDeLaPausa(widget.onCompletado);
    }
  }

  EstadoTarjeta _estado({
    required int indice,
    required int? seleccionada,
    required int? fallida,
  }) {
    if (_unidas.contains(indice)) {
      return EstadoTarjeta.correcta;
    }
    if (fallida == indice) {
      return EstadoTarjeta.incorrecta;
    }
    if (seleccionada == indice) {
      return EstadoTarjeta.seleccionada;
    }

    return EstadoTarjeta.normal;
  }

  Widget _columna({
    required List<int> orden,
    required ElementoVisual Function(int indice) elemento,
    required int? seleccionada,
    required int? fallida,
    required ValueChanged<int> onTocar,
    required String lado,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final indice in orden) ...[
          TarjetaElemento(
            key: ValueKey('$lado-$indice'),
            elemento: elemento(indice),
            estado: _estado(
              indice: indice,
              seleccionada: seleccionada,
              fallida: fallida,
            ),
            esCompacta: true,
            tamanoEmoji: 34,
            onTap: _unidas.contains(indice) ? null : () => onTocar(indice),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fallo = _fallo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IndicadorAvance(actual: _unidas.length, total: _pares.length),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _columna(
                orden: List<int>.generate(_pares.length, (i) => i),
                elemento: (indice) => _pares[indice].izquierda,
                seleccionada: _izquierda,
                fallida: fallo?.$1,
                onTocar: _tocarIzquierda,
                lado: 'izquierda',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _columna(
                orden: _ordenDerecha,
                elemento: (indice) => _pares[indice].derecha,
                seleccionada: _derecha,
                fallida: fallo?.$2,
                onTocar: _tocarDerecha,
                lado: 'derecha',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
