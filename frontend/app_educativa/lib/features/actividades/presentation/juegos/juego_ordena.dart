import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/actividad.dart';
import '../widgets/tarjeta_elemento.dart';
import 'juego_base.dart';

/// Ordena: tocar los pasos en el orden correcto. Cada paso acertado sube a
/// su lugar numerado.
class JuegoOrdena extends JuegoBase {
  final ActividadOrdena actividad;

  const JuegoOrdena({
    super.key,
    required this.actividad,
    required super.onResponder,
    required super.onCompletado,
    required super.random,
    required super.pausa,
  });

  @override
  State<JuegoOrdena> createState() => _JuegoOrdenaState();
}

class _JuegoOrdenaState extends State<JuegoOrdena>
    with EstadoJuego<JuegoOrdena> {
  late final List<int> _mezclados =
      indicesMezclados(widget.actividad.pasos.length);
  int _colocados = 0;
  int? _fallido;

  List<ElementoVisual> get _pasos => widget.actividad.pasos;

  bool get _terminado => _colocados == _pasos.length;

  void _tocar(int indice) {
    if (_terminado || indice < _colocados) {
      return;
    }

    voz.hablar(_pasos[indice].texto);
    final esElSiguiente = indice == _colocados;

    setState(() {
      if (esElSiguiente) {
        _colocados++;
        _fallido = null;
      } else {
        _fallido = indice;
      }
    });
    widget.onResponder(esElSiguiente);

    if (_terminado) {
      despuesDeLaPausa(widget.onCompletado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = _mezclados.where((indice) => indice >= _colocados);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IndicadorAvance(actual: _colocados, total: _pasos.length),
        const SizedBox(height: 20),
        for (var posicion = 0; posicion < _pasos.length; posicion++) ...[
          _Lugar(
            numero: posicion + 1,
            elemento: posicion < _colocados ? _pasos[posicion] : null,
          ),
          const SizedBox(height: 8),
        ],
        if (!_terminado) ...[
          const SizedBox(height: 16),
          Text(
            _colocados == 0 ? '¿Qué va primero?' : '¿Qué sigue?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final indice in pendientes) ...[
            TarjetaElemento(
              key: ValueKey('paso-$indice'),
              elemento: _pasos[indice],
              estado: _fallido == indice
                  ? EstadoTarjeta.incorrecta
                  : EstadoTarjeta.normal,
              onTap: () => _tocar(indice),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _Lugar extends StatelessWidget {
  final int numero;
  final ElementoVisual? elemento;

  const _Lugar({required this.numero, required this.elemento});

  @override
  Widget build(BuildContext context) {
    final contenido = elemento;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: contenido == null ? AppTheme.grisSuave : AppTheme.verdeSuave,
        borderRadius: BorderRadius.circular(AppTheme.radio),
        border: Border.all(
          color: contenido == null ? AppTheme.borde : AppTheme.verde,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                contenido == null ? AppTheme.textoSecundario : AppTheme.verde,
            foregroundColor: Colors.white,
            child: Text(
              '$numero',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          if (contenido != null) ...[
            Text(contenido.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                contenido.texto,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ] else
            const Text(
              '?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textoSecundario,
              ),
            ),
        ],
      ),
    );
  }
}
