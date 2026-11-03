import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/boton_grande.dart';
import '../../domain/actividad.dart';
import '../widgets/boton_pista.dart';
import '../widgets/efectos.dart';
import '../widgets/tarjeta_elemento.dart';
import 'juego_base.dart';

/// Escucha y toca: la voz dice qué buscar ("¿Qué nos da sombra y
/// frutas?") y el niño toca el dibujo. Pensado para primero: se juega
/// escuchando y mirando; el texto solo acompaña.
class JuegoEscucha extends JuegoBase {
  final ActividadEscucha actividad;

  const JuegoEscucha({
    super.key,
    required this.actividad,
    required super.onResponder,
    required super.onCompletado,
    required super.random,
    required super.pausa,
    super.moduloId,
    super.lecturaAsistida,
  });

  @override
  State<JuegoEscucha> createState() => _JuegoEscuchaState();
}

class _JuegoEscuchaState extends State<JuegoEscucha>
    with EstadoJuego<JuegoEscucha> {
  int _indice = 0;
  late List<int> _orden;
  final Set<int> _falladas = {};
  bool _acerto = false;
  bool _leida = false;

  PreguntaElige get _ronda => widget.actividad.rondas[_indice];

  @override
  void initState() {
    super.initState();
    _orden = indicesMezclados(_ronda.opciones.length);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_leida) {
      _leida = true;
      _escuchar();
    }
  }

  void _escuchar() => voz.hablar(_ronda.paraLeer);

  void _tocar(int opcion) {
    if (_acerto || _falladas.contains(opcion)) {
      return;
    }

    final esCorrecta = opcion == _ronda.correcta;

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
    if (_indice + 1 >= widget.actividad.rondas.length) {
      widget.onCompletado();
      return;
    }

    setState(() {
      _indice++;
      _orden = indicesMezclados(_ronda.opciones.length);
      _falladas.clear();
      _acerto = false;
    });
    _escuchar();
  }

  EstadoTarjeta _estadoDe(int opcion) {
    if (_falladas.contains(opcion)) {
      return EstadoTarjeta.incorrecta;
    }
    if (_acerto) {
      return opcion == _ronda.correcta
          ? EstadoTarjeta.correcta
          : EstadoTarjeta.deshabilitada;
    }

    return EstadoTarjeta.normal;
  }

  @override
  Widget build(BuildContext context) {
    final pista = _ronda.pista;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IndicadorAvance(
          actual: _indice + (_acerto ? 1 : 0),
          total: widget.actividad.rondas.length,
        ),
        const SizedBox(height: 16),
        BotonGrande(
          key: const ValueKey('boton-escuchar'),
          texto: 'Escuchar otra vez',
          icono: Icons.hearing_rounded,
          color: AppTheme.morado,
          onPressed: _escuchar,
        ),
        // La consigna también se ve, pequeña, para quien ya lee.
        Aparecer(
          key: ValueKey('consigna-$_indice'),
          child: Text(
            _ronda.enunciado,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.morado,
            ),
          ),
        ),
        if (pista != null && widget.moduloId != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: BotonPista(pista: pista, moduloId: widget.moduloId!),
          ),
        ],
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, limites) {
            final ancho = (limites.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (var posicion = 0; posicion < _orden.length; posicion++)
                  SizedBox(
                    width: ancho,
                    child: TarjetaElemento(
                      key: ValueKey('opcion-$_indice-${_orden[posicion]}'),
                      elemento: _ronda.opciones[_orden[posicion]],
                      estado: _estadoDe(_orden[posicion]),
                      tamanoEmoji: 80,
                      vertical: true,
                      color: colorJuego(posicion),
                      onTap: () => _tocar(_orden[posicion]),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
