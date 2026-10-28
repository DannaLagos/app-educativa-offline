import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/actividad.dart';
import '../widgets/boton_pista.dart';
import '../widgets/tarjeta_elemento.dart';
import 'juego_base.dart';

/// Elige: tocar la respuesta correcta entre 2 o 3 opciones grandes.
class JuegoElige extends JuegoBase {
  final ActividadElige actividad;

  const JuegoElige({
    super.key,
    required this.actividad,
    required super.onResponder,
    required super.onCompletado,
    required super.random,
    required super.pausa,
    super.moduloId,
  });

  @override
  State<JuegoElige> createState() => _JuegoEligeState();
}

class _JuegoEligeState extends State<JuegoElige>
    with EstadoJuego<JuegoElige> {
  int _indice = 0;
  late List<int> _orden;
  final Set<int> _falladas = {};
  bool _acerto = false;

  PreguntaElige get _pregunta => widget.actividad.preguntas[_indice];

  @override
  void initState() {
    super.initState();
    _prepararPregunta();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_indice == 0 && !_acerto && _falladas.isEmpty) {
      voz.hablar(_pregunta.enunciado);
    }
  }

  void _prepararPregunta() {
    _orden = indicesMezclados(_pregunta.opciones.length);
    _falladas.clear();
    _acerto = false;
  }

  void _elegir(int opcion) {
    if (_acerto || _falladas.contains(opcion)) {
      return;
    }

    final esCorrecta = opcion == _pregunta.correcta;

    setState(() {
      if (esCorrecta) {
        _acerto = true;
      } else {
        _falladas.add(opcion);
      }
    });
    widget.onResponder(esCorrecta);

    if (esCorrecta) {
      despuesDeLaPausa(_siguiente);
    }
  }

  void _siguiente() {
    if (_indice + 1 >= widget.actividad.preguntas.length) {
      widget.onCompletado();
      return;
    }

    setState(() {
      _indice++;
      _prepararPregunta();
    });
    voz.hablar(_pregunta.enunciado);
  }

  EstadoTarjeta _estadoDe(int opcion) {
    if (_falladas.contains(opcion)) {
      return EstadoTarjeta.incorrecta;
    }
    if (_acerto) {
      return opcion == _pregunta.correcta
          ? EstadoTarjeta.correcta
          : EstadoTarjeta.deshabilitada;
    }

    return EstadoTarjeta.normal;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IndicadorAvance(
          actual: _indice + (_acerto ? 1 : 0),
          total: widget.actividad.preguntas.length,
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _pregunta.enunciado,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.texto,
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Escuchar la pregunta',
              iconSize: 32,
              onPressed: () => voz.hablar(_pregunta.enunciado),
              icon: const Icon(Icons.volume_up_rounded),
            ),
          ],
        ),
        if (_pregunta.pista != null && widget.moduloId != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: BotonPista(
              pista: _pregunta.pista!,
              moduloId: widget.moduloId!,
            ),
          ),
        ],
        const SizedBox(height: 20),
        for (final opcion in _orden) ...[
          TarjetaElemento(
            key: ValueKey('opcion-$_indice-$opcion'),
            elemento: _pregunta.opciones[opcion],
            estado: _estadoDe(opcion),
            tamanoEmoji: 48,
            onTap: () => _elegir(opcion),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
