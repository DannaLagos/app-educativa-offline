import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/actividad.dart';
import '../widgets/tarjeta_elemento.dart';
import 'juego_base.dart';

/// Arma la oración: las palabras aparecen mezcladas y el niño las toca en
/// orden. Cada palabra correcta sube a la oración.
class JuegoArma extends JuegoBase {
  final ActividadArma actividad;

  const JuegoArma({
    super.key,
    required this.actividad,
    required super.onResponder,
    required super.onCompletado,
    required super.random,
    required super.pausa,
  });

  @override
  State<JuegoArma> createState() => _JuegoArmaState();
}

class _JuegoArmaState extends State<JuegoArma> with EstadoJuego<JuegoArma> {
  int _indice = 0;
  int _colocadas = 0;
  int? _fallida;
  late List<int> _mezcladas;

  OracionArma get _oracion => widget.actividad.oraciones[_indice];

  bool get _oracionLista => _colocadas == _oracion.partes.length;

  @override
  void initState() {
    super.initState();
    _mezcladas = indicesMezclados(_oracion.partes.length);
  }

  void _tocar(int parte) {
    if (_oracionLista || parte < _colocadas) {
      return;
    }

    final partes = _oracion.partes;
    // Si una palabra se repite (por ejemplo, "la"), vale cualquiera de las
    // dos fichas.
    final esLaSiguiente = partes[parte] == partes[_colocadas];

    setState(() {
      if (esLaSiguiente) {
        // Intercambia para que la ficha tocada quede en su lugar.
        if (parte != _colocadas) {
          final i = _mezcladas.indexOf(parte);
          final j = _mezcladas.indexOf(_colocadas);
          _mezcladas[i] = _colocadas;
          _mezcladas[j] = parte;
        }
        _colocadas++;
        _fallida = null;
      } else {
        _fallida = parte;
      }
    });
    widget.onResponder(esLaSiguiente);

    if (_oracionLista) {
      voz.hablar(_oracion.texto);
      despuesDeLaPausa(_siguiente);
    }
  }

  void _siguiente() {
    if (_indice + 1 >= widget.actividad.oraciones.length) {
      widget.onCompletado();
      return;
    }

    setState(() {
      _indice++;
      _colocadas = 0;
      _fallida = null;
      _mezcladas = indicesMezclados(_oracion.partes.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final partes = _oracion.partes;
    final pendientes = _mezcladas.where((indice) => indice >= _colocadas);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IndicadorAvance(
          actual: _indice + (_oracionLista ? 1 : 0),
          total: widget.actividad.oraciones.length,
        ),
        const SizedBox(height: 20),
        Text(
          _oracion.emoji,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 56),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _oracionLista ? AppTheme.verdeSuave : AppTheme.grisSuave,
            borderRadius: BorderRadius.circular(AppTheme.radio),
            border: Border.all(
              color: _oracionLista ? AppTheme.verde : AppTheme.borde,
              width: 2,
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < _colocadas; i++)
                Text(
                  partes[i],
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.verde,
                  ),
                ),
              if (!_oracionLista)
                Container(
                  width: 60,
                  height: 4,
                  color: AppTheme.textoSecundario,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (!_oracionLista)
          Text(
            _colocadas == 0 ? '¿Con qué palabra empieza?' : '¿Qué palabra sigue?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final indice in pendientes)
              _Ficha(
                key: ValueKey('ficha-$_indice-$indice'),
                texto: partes[indice],
                fallo: _fallida == indice,
                onTap: () => _tocar(indice),
              ),
          ],
        ),
      ],
    );
  }
}

class _Ficha extends StatelessWidget {
  final String texto;
  final bool fallo;
  final VoidCallback onTap;

  const _Ficha({
    super.key,
    required this.texto,
    required this.fallo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: texto,
      excludeSemantics: true,
      child: Material(
        color: fallo ? AppTheme.ambarSuave : AppTheme.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: fallo ? AppTheme.ambar : AppTheme.azul,
            width: 3,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Text(
              texto,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}
