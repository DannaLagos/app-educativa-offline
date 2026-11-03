import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/actividad.dart';
import '../widgets/boton_pista.dart';
import '../widgets/efectos.dart';
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
    super.lecturaAsistida,
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

  /// Opción que la voz está leyendo (para resaltarla), o null.
  int? _leyendo;

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
      _leerPregunta();
    }
  }

  void _prepararPregunta() {
    _orden = indicesMezclados(_pregunta.opciones.length);
    _falladas.clear();
    _acerto = false;
    _leyendo = null;
  }

  /// Lee la pregunta y, en lectura asistida, también cada opción en el
  /// orden en que aparecen, iluminando la que se está leyendo.
  void _leerPregunta() {
    if (!widget.lecturaAsistida) {
      voz.hablar(_pregunta.paraLeer);
      return;
    }

    leerEnOrden(
      [
        _pregunta.paraLeer,
        for (final opcion in _orden) _pregunta.opciones[opcion].paraLeer,
      ],
      (leido) => setState(
        () => _leyendo = leido == null || leido == 0 ? null : _orden[leido - 1],
      ),
    );
  }

  void _escucharOpcion(int opcion) {
    cortarLectura();
    setState(() => _leyendo = null);
    voz.hablar(_pregunta.opciones[opcion].paraLeer);
  }

  void _elegir(int opcion) {
    if (_acerto || _falladas.contains(opcion)) {
      return;
    }

    final esCorrecta = opcion == _pregunta.correcta;
    cortarLectura();

    setState(() {
      _leyendo = null;
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
    _leerPregunta();
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

  Widget _opcion(int posicion) {
    final opcion = _orden[posicion];
    final asistida = widget.lecturaAsistida;

    return TarjetaElemento(
      key: ValueKey('opcion-$_indice-$opcion'),
      elemento: _pregunta.opciones[opcion],
      estado: _estadoDe(opcion),
      tamanoEmoji: asistida ? 76 : 50,
      // Cada opción de un color: se distinguen sin tener que leer.
      color: colorJuego(posicion),
      vertical: asistida,
      resaltada: _leyendo == opcion,
      onEscuchar: asistida ? () => _escucharOpcion(opcion) : null,
      onTap: () => _elegir(opcion),
    );
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
        // La pregunta entra con un saltito cada vez que cambia.
        Aparecer(
          key: ValueKey('pregunta-$_indice'),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
            decoration: BoxDecoration(
              color: AppTheme.superficie,
              borderRadius: BorderRadius.circular(AppTheme.radio),
              border: Border.all(color: AppTheme.amarillo, width: 4),
              boxShadow: const [
                BoxShadow(color: Color(0x55FFC93C), offset: Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _pregunta.enunciado,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.texto,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Escuchar la pregunta',
                  iconSize: 32,
                  onPressed: _leerPregunta,
                  icon: const Icon(Icons.volume_up_rounded),
                ),
              ],
            ),
          ),
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
        if (widget.lecturaAsistida)
          // Dibujos grandes, dos por fila: se elige mirando, no leyendo.
          LayoutBuilder(
            builder: (context, limites) {
              final ancho = (limites.maxWidth - 12) / 2;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (var posicion = 0; posicion < _orden.length; posicion++)
                    SizedBox(width: ancho, child: _opcion(posicion)),
                ],
              );
            },
          )
        else
          for (var posicion = 0; posicion < _orden.length; posicion++) ...[
            _opcion(posicion),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
