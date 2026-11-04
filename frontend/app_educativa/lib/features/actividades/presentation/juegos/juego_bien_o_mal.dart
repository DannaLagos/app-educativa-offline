import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/dibujo.dart';
import '../../domain/actividad.dart';
import '../widgets/boton_pista.dart';
import '../widgets/efectos.dart';
import '../widgets/tarjeta_elemento.dart';
import 'juego_base.dart';

/// ¿Está bien o está mal? Aparece una situación con su dibujo, la voz la
/// dice y el niño toca 😄 o 😢. Pensado para primero: no hay que leer.
class JuegoBienOMal extends JuegoBase {
  final ActividadBienOMal actividad;

  const JuegoBienOMal({
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
  State<JuegoBienOMal> createState() => _JuegoBienOMalState();
}

class _JuegoBienOMalState extends State<JuegoBienOMal>
    with EstadoJuego<JuegoBienOMal> {
  late final List<int> _orden =
      indicesMezclados(widget.actividad.situaciones.length);
  int _indice = 0;
  bool _acerto = false;

  /// Botón equivocado que se tocó (true = "bien"), para sacudirlo.
  bool? _fallo;
  int _sacudidas = 0;
  int _rebotes = 0;
  bool _leida = false;

  Situacion get _situacion => widget.actividad.situaciones[_orden[_indice]];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_leida) {
      _leida = true;
      _leer();
    }
  }

  void _leer() => voz.hablar(_situacion.elemento.paraLeer);

  void _responder(bool diceQueEstaBien) {
    if (_acerto) {
      return;
    }

    final esCorrecto = diceQueEstaBien == _situacion.estaBien;

    setState(() {
      if (esCorrecto) {
        _acerto = true;
        _fallo = null;
        _rebotes++;
      } else {
        _fallo = diceQueEstaBien;
        _sacudidas++;
      }
    });
    widget.onResponder(esCorrecto);

    if (esCorrecto) {
      despuesDeLaPausa(_siguiente);
    }
  }

  void _siguiente() {
    if (_indice + 1 >= _orden.length) {
      widget.onCompletado();
      return;
    }

    setState(() {
      _indice++;
      _acerto = false;
      _fallo = null;
    });
    _leer();
  }

  @override
  Widget build(BuildContext context) {
    final situacion = _situacion;
    final pista = situacion.pista;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IndicadorAvance(actual: _indice + (_acerto ? 1 : 0), total: _orden.length),
        const SizedBox(height: 16),
        // La situación entra con un saltito cada vez que cambia.
        Aparecer(
          key: ValueKey('situacion-$_indice'),
          child: _TarjetaSituacion(
            elemento: situacion.elemento,
            resuelta: _acerto,
            onEscuchar: _leer,
          ),
        ),
        if (pista != null && widget.moduloId != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: BotonPista(pista: pista, moduloId: widget.moduloId!),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _BotonRespuesta(
                key: const ValueKey('boton-bien'),
                emoji: '😄',
                texto: 'Está bien',
                color: AppTheme.verde,
                sacudidas: _fallo == true ? _sacudidas : 0,
                rebotes: _acerto && situacion.estaBien ? _rebotes : 0,
                apagado: _acerto && !situacion.estaBien,
                onTap: () => _responder(true),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _BotonRespuesta(
                key: const ValueKey('boton-mal'),
                emoji: '😢',
                texto: 'Está mal',
                color: AppTheme.rosa,
                sacudidas: _fallo == false ? _sacudidas : 0,
                rebotes: _acerto && !situacion.estaBien ? _rebotes : 0,
                apagado: _acerto && situacion.estaBien,
                onTap: () => _responder(false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TarjetaSituacion extends StatelessWidget {
  final ElementoVisual elemento;
  final bool resuelta;
  final VoidCallback onEscuchar;

  const _TarjetaSituacion({
    required this.elemento,
    required this.resuelta,
    required this.onEscuchar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(AppTheme.radio),
        border: Border.all(
          color: resuelta ? AppTheme.verde : AppTheme.amarillo,
          width: 4,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x55FFC93C), offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 150,
            height: 150,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.amarilloSuave,
              shape: BoxShape.circle,
            ),
            child: Dibujo(elemento.emoji, tamano: 110),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  elemento.texto,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.texto,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Escuchar otra vez',
                iconSize: 32,
                onPressed: onEscuchar,
                icon: const Icon(Icons.volume_up_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Botón grande de color con una carita: así el niño responde sin leer.
class _BotonRespuesta extends StatelessWidget {
  static const double _relieve = 6;

  final String emoji;
  final String texto;
  final Color color;
  final int sacudidas;
  final int rebotes;
  final bool apagado;
  final VoidCallback onTap;

  const _BotonRespuesta({
    super.key,
    required this.emoji,
    required this.texto,
    required this.color,
    required this.sacudidas,
    required this.rebotes,
    required this.apagado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(AppTheme.radio);
    final fondo = apagado ? AppTheme.gris : color;

    return Semantics(
      button: true,
      label: texto,
      excludeSemantics: true,
      child: Sacudir(
        veces: sacudidas,
        child: Rebotar(
          veces: rebotes,
          child: Opacity(
            opacity: apagado ? 0.4 : 1,
            child: Container(
              margin: const EdgeInsets.only(bottom: _relieve),
              decoration: BoxDecoration(
                color: fondo,
                borderRadius: radio,
                boxShadow: [
                  BoxShadow(color: relieve(fondo), offset: const Offset(0, _relieve)),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: radio,
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Dibujo(emoji, tamano: 64),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          texto,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
