import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/actividad.dart';
import 'juego_base.dart';

/// Arrastra y suelta: todas las tarjetas están a la vista y el niño las
/// arrastra con el dedo a su canasta. Si una tarjeta va a la canasta
/// equivocada, regresa a su sitio.
///
/// Para niños a los que les cuesta arrastrar, también se puede tocar una
/// tarjeta y luego la canasta.
class JuegoArrastra extends JuegoBase {
  final ActividadArrastra actividad;

  const JuegoArrastra({
    super.key,
    required this.actividad,
    required super.onResponder,
    required super.onCompletado,
    required super.random,
    required super.pausa,
  });

  @override
  State<JuegoArrastra> createState() => _JuegoArrastraState();
}

class _JuegoArrastraState extends State<JuegoArrastra>
    with EstadoJuego<JuegoArrastra> {
  late final List<int> _orden =
      indicesMezclados(widget.actividad.tarjetas.length);
  final Map<String, List<int>> _enCanasta = {};
  int? _seleccionada;
  String? _canastaFallida;

  List<TarjetaClasifica> get _tarjetas => widget.actividad.tarjetas;

  Iterable<int> get _pendientes => _orden.where(
        (indice) => !_enCanasta.values.any((lista) => lista.contains(indice)),
      );

  void _soltar(int tarjeta, GrupoClasifica grupo) {
    final esCorrecto = _tarjetas[tarjeta].grupo == grupo.id;

    setState(() {
      _seleccionada = null;
      if (esCorrecto) {
        _canastaFallida = null;
        (_enCanasta[grupo.id] ??= []).add(tarjeta);
      } else {
        _canastaFallida = grupo.id;
      }
    });
    widget.onResponder(esCorrecto);

    if (esCorrecto && _pendientes.isEmpty) {
      despuesDeLaPausa(widget.onCompletado);
    }
  }

  void _tocarTarjeta(int tarjeta) {
    voz.hablar(_tarjetas[tarjeta].elemento.texto);
    setState(() {
      _canastaFallida = null;
      _seleccionada = _seleccionada == tarjeta ? null : tarjeta;
    });
  }

  void _tocarCanasta(GrupoClasifica grupo) {
    final seleccionada = _seleccionada;

    if (seleccionada == null) {
      voz.hablar(grupo.elemento.texto);
      return;
    }
    _soltar(seleccionada, grupo);
  }

  @override
  Widget build(BuildContext context) {
    final grupos = widget.actividad.grupos;
    final pendientes = _pendientes.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < grupos.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _CanastaDestino(
                  grupo: grupos[i],
                  contenido: [
                    for (final indice in _enCanasta[grupos[i].id] ?? <int>[])
                      _tarjetas[indice].elemento,
                  ],
                  fallo: _canastaFallida == grupos[i].id,
                  hayTarjetaElegida: _seleccionada != null,
                  onSoltar: (tarjeta) => _soltar(tarjeta, grupos[i]),
                  onTap: () => _tocarCanasta(grupos[i]),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        if (pendientes.isNotEmpty)
          const Text(
            'Arrastra cada dibujo a su canasta 👆',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final indice in pendientes)
              _TarjetaArrastrable(
                key: ValueKey('arrastrable-$indice'),
                indice: indice,
                elemento: _tarjetas[indice].elemento,
                seleccionada: _seleccionada == indice,
                onTap: () => _tocarTarjeta(indice),
              ),
          ],
        ),
      ],
    );
  }
}

class _TarjetaArrastrable extends StatelessWidget {
  final int indice;
  final ElementoVisual elemento;
  final bool seleccionada;
  final VoidCallback onTap;

  const _TarjetaArrastrable({
    super.key,
    required this.indice,
    required this.elemento,
    required this.seleccionada,
    required this.onTap,
  });

  Widget _tarjeta({double elevacion = 0, double opacidad = 1}) {
    return Opacity(
      opacity: opacidad,
      child: Material(
        elevation: elevacion,
        color: seleccionada ? AppTheme.azulClaro : AppTheme.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radio),
          side: BorderSide(
            color: seleccionada ? AppTheme.azul : AppTheme.borde,
            width: seleccionada ? 3 : 2,
          ),
        ),
        // Ancho fijo pero alto libre: el texto completo siempre cabe, aunque
        // ocupe varias líneas o el teléfono use letra grande.
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: 150)
              .copyWith(minHeight: 120),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(elemento.emoji, style: const TextStyle(fontSize: 42)),
                const SizedBox(height: 6),
                Text(
                  elemento.texto,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.texto,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: elemento.texto,
      excludeSemantics: true,
      child: Draggable<int>(
        data: indice,
        feedback: Transform.scale(scale: 1.1, child: _tarjeta(elevacion: 8)),
        childWhenDragging: _tarjeta(opacidad: 0.3),
        child: GestureDetector(onTap: onTap, child: _tarjeta()),
      ),
    );
  }
}

class _CanastaDestino extends StatelessWidget {
  final GrupoClasifica grupo;
  final List<ElementoVisual> contenido;
  final bool fallo;
  final bool hayTarjetaElegida;
  final ValueChanged<int> onSoltar;
  final VoidCallback onTap;

  const _CanastaDestino({
    required this.grupo,
    required this.contenido,
    required this.fallo,
    required this.hayTarjetaElegida,
    required this.onSoltar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      key: ValueKey('destino-${grupo.id}'),
      onAcceptWithDetails: (detalles) => onSoltar(detalles.data),
      builder: (context, candidatas, _) {
        final encima = candidatas.isNotEmpty;
        final color = fallo
            ? AppTheme.ambar
            : encima || hayTarjetaElegida
                ? AppTheme.verde
                : AppTheme.azul;

        return Semantics(
          button: true,
          label: grupo.elemento.texto,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              constraints: const BoxConstraints(minHeight: 170),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: fallo
                    ? AppTheme.ambarSuave
                    : encima
                        ? AppTheme.verdeSuave
                        : AppTheme.azulSuave,
                borderRadius: BorderRadius.circular(AppTheme.radio),
                border: Border.all(color: color, width: encima ? 4 : 3),
              ),
              child: Column(
                children: [
                  Text(
                    grupo.elemento.emoji,
                    style: const TextStyle(fontSize: 44),
                  ),
                  Text(
                    grupo.elemento.texto,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    children: [
                      for (final elemento in contenido)
                        Text(
                          elemento.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
