import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/actividad.dart';
import '../../domain/cuadricula_sopa.dart';
import '../widgets/tarjeta_elemento.dart';
import 'juego_base.dart';

/// Sopa de letras: el niño toca la primera y la última letra de cada
/// palabra escondida (en horizontal o vertical).
class JuegoSopa extends JuegoBase {
  final ActividadSopa actividad;

  const JuegoSopa({
    super.key,
    required this.actividad,
    required super.onResponder,
    required super.onCompletado,
    required super.random,
    required super.pausa,
  });

  @override
  State<JuegoSopa> createState() => _JuegoSopaState();
}

class _JuegoSopaState extends State<JuegoSopa> with EstadoJuego<JuegoSopa> {
  static const List<Color> _coloresEncontradas = [
    Color(0xFFB8F0D2),
    Color(0xFFBFE3FF),
    Color(0xFFFFE3A8),
    Color(0xFFE8D4FF),
    Color(0xFFFFCFCF),
    Color(0xFFD7F5C9),
  ];

  late final CuadriculaSopa _cuadricula = CuadriculaSopa.generar(
    widget.actividad.palabras.map((palabra) => palabra.texto).toList(),
    widget.actividad.tamano,
    widget.random,
  );

  /// Palabras encontradas, en el orden en que se encontraron.
  final List<UbicacionPalabra> _encontradas = [];
  (int, int)? _primera;
  List<(int, int)> _fallidas = const [];

  bool _estaEncontrada(ElementoVisual palabra) => _encontradas
      .any((ubicacion) => ubicacion.palabra == normalizarPalabra(palabra.texto));

  Color? _colorDe((int, int) celda) {
    for (var i = _encontradas.length - 1; i >= 0; i--) {
      if (_encontradas[i].celdas.contains(celda)) {
        return _coloresEncontradas[i % _coloresEncontradas.length];
      }
    }

    return null;
  }

  void _tocar((int, int) celda) {
    final primera = _primera;

    if (primera == null || primera == celda) {
      setState(() {
        _primera = primera == celda ? null : celda;
        _fallidas = const [];
      });
      return;
    }

    final enLinea = primera.$1 == celda.$1 || primera.$2 == celda.$2;

    if (!enLinea) {
      // Solo se buscan palabras en línea recta: empieza una nueva selección.
      setState(() => _primera = celda);
      return;
    }

    final ubicacion = _cuadricula.buscar(primera, celda);
    final esNueva = ubicacion != null && !_encontradas.contains(ubicacion);

    setState(() {
      _primera = null;
      if (esNueva) {
        _encontradas.add(ubicacion!);
        _fallidas = const [];
      } else {
        _fallidas = [primera, celda];
      }
    });
    widget.onResponder(esNueva);

    if (esNueva) {
      voz.hablar(_textoOriginal(ubicacion!.palabra));
      if (_encontradas.length == widget.actividad.palabras.length) {
        despuesDeLaPausa(widget.onCompletado);
      }
    }
  }

  String _textoOriginal(String normalizada) {
    for (final palabra in widget.actividad.palabras) {
      if (normalizarPalabra(palabra.texto) == normalizada) {
        return palabra.texto;
      }
    }

    return normalizada;
  }

  @override
  Widget build(BuildContext context) {
    final lado = _cuadricula.tamano;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IndicadorAvance(
          actual: _encontradas.length,
          total: widget.actividad.palabras.length,
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final palabra in widget.actividad.palabras)
              _PalabraBuscada(
                palabra: palabra,
                encontrada: _estaEncontrada(palabra),
              ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Toca la primera letra y luego la última de cada palabra.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.superficie,
              borderRadius: BorderRadius.circular(AppTheme.radio),
              border: Border.all(color: AppTheme.azul, width: 2),
            ),
            child: Column(
              children: [
                for (var fila = 0; fila < lado; fila++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var columna = 0; columna < lado; columna++)
                          Expanded(
                            child: _Celda(
                              key: ValueKey('celda-$fila-$columna'),
                              letra: _cuadricula.letra(fila, columna),
                              color: _colorDe((fila, columna)),
                              seleccionada: _primera == (fila, columna),
                              fallida: _fallidas.contains((fila, columna)),
                              onTap: () => _tocar((fila, columna)),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PalabraBuscada extends StatelessWidget {
  final ElementoVisual palabra;
  final bool encontrada;

  const _PalabraBuscada({required this.palabra, required this.encontrada});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: encontrada ? AppTheme.verdeSuave : AppTheme.azulSuave,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: encontrada ? AppTheme.verde : AppTheme.azulClaro,
          width: 2,
        ),
      ),
      child: Text(
        '${encontrada ? '✅' : palabra.emoji} ${palabra.texto}',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: encontrada ? AppTheme.verde : AppTheme.azul,
          decoration: encontrada ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}

class _Celda extends StatelessWidget {
  final String letra;
  final Color? color;
  final bool seleccionada;
  final bool fallida;
  final VoidCallback onTap;

  const _Celda({
    super.key,
    required this.letra,
    required this.color,
    required this.seleccionada,
    required this.fallida,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fondo = fallida
        ? AppTheme.ambarSuave
        : seleccionada
            ? AppTheme.azul
            : color ?? Colors.transparent;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            letra,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: seleccionada ? Colors.white : AppTheme.texto,
            ),
          ),
        ),
      ),
    );
  }
}
