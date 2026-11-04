import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/dibujo.dart';
import '../../domain/actividad.dart';
import '../widgets/efectos.dart';
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
    super.lecturaAsistida,
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

    voz.hablar(_pasos[indice].paraLeer);
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
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.morado,
            ),
          ),
          const SizedBox(height: 12),
          for (final indice in pendientes) ...[
            TarjetaElemento(
              key: ValueKey('paso-$indice'),
              elemento: _pasos[indice],
              estado: _fallido == indice
                  ? EstadoTarjeta.incorrecta
                  : EstadoTarjeta.normal,
              // El color no delata el orden: depende de dónde quedó la
              // tarjeta al mezclar.
              color: colorJuego(_mezclados.indexOf(indice) + 2),
              // En lectura asistida se puede escuchar cada paso antes de
              // elegirlo, sin que cuente como intento.
              onEscuchar: widget.lecturaAsistida
                  ? () => voz.hablar(_pasos[indice].paraLeer)
                  : null,
              onTap: () => _tocar(indice),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

/// Casilla numerada del camino. Cada número tiene su color; vacía muestra
/// un "?" y, llena, el paso aparece con un saltito.
class _Lugar extends StatelessWidget {
  static const double _tamanoNumero = 46;

  final int numero;
  final ElementoVisual? elemento;

  const _Lugar({required this.numero, required this.elemento});

  @override
  Widget build(BuildContext context) {
    final contenido = elemento;
    final color = colorJuego(numero - 1);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: contenido == null ? AppTheme.superficie : suave(color),
        borderRadius: BorderRadius.circular(AppTheme.radio),
        border: Border.all(
          color: contenido == null ? AppTheme.borde : color,
          width: 3,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: _tamanoNumero,
            height: _tamanoNumero,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: relieve(color), offset: const Offset(0, 3)),
              ],
            ),
            child: Text(
              '$numero',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (contenido != null)
            Expanded(
              child: Aparecer(
                child: Row(
                  children: [
                    Dibujo(contenido.emoji, tamano: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        contenido.texto,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.verde,
                      size: 30,
                    ),
                  ],
                ),
              ),
            )
          else
            const Text(
              '?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.textoSecundario,
              ),
            ),
        ],
      ),
    );
  }
}
