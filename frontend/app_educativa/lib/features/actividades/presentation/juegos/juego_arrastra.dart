import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/dibujo.dart';
import '../../domain/actividad.dart';
import '../widgets/efectos.dart';
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

  /// Para sacudir la canasta equivocada y hacer rebotar la correcta.
  final Map<String, int> _sacudidas = {};
  final Map<String, int> _rebotes = {};

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
        _rebotes[grupo.id] = (_rebotes[grupo.id] ?? 0) + 1;
      } else {
        _canastaFallida = grupo.id;
        _sacudidas[grupo.id] = (_sacudidas[grupo.id] ?? 0) + 1;
      }
    });
    widget.onResponder(esCorrecto);

    if (esCorrecto && _pendientes.isEmpty) {
      despuesDeLaPausa(widget.onCompletado);
    }
  }

  void _tocarTarjeta(int tarjeta) {
    voz.hablar(_tarjetas[tarjeta].elemento.paraLeer);
    setState(() {
      _canastaFallida = null;
      _seleccionada = _seleccionada == tarjeta ? null : tarjeta;
    });
  }

  void _tocarCanasta(GrupoClasifica grupo) {
    final seleccionada = _seleccionada;

    if (seleccionada == null) {
      voz.hablar(grupo.elemento.paraLeer);
      return;
    }
    _soltar(seleccionada, grupo);
  }

  // Verde y rosa para las dos canastas más comunes ("sí" y "no").
  static Color _colorCanasta(int indice) =>
      const [AppTheme.verde, AppTheme.rosa, AppTheme.azul, AppTheme.naranja][
          indice % 4];

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
                child: Sacudir(
                  veces: _sacudidas[grupos[i].id] ?? 0,
                  child: Rebotar(
                    veces: _rebotes[grupos[i].id] ?? 0,
                    child: _CanastaDestino(
                  grupo: grupos[i],
                  color: _colorCanasta(i),
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
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppTheme.morado,
            ),
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
                color: colorJuego(indice),
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
  final Color color;
  final VoidCallback onTap;

  const _TarjetaArrastrable({
    super.key,
    required this.indice,
    required this.elemento,
    required this.seleccionada,
    required this.color,
    required this.onTap,
  });

  Widget _tarjeta({bool levantada = false, double opacidad = 1}) {
    final arriba = levantada || seleccionada;

    return Opacity(
      opacity: opacidad,
      child: Transform.translate(
        // Elegida o en el aire, la tarjeta "se levanta".
        offset: Offset(0, arriba ? -6 : 0),
        child: Container(
          decoration: BoxDecoration(
            color: seleccionada ? suave(color) : AppTheme.superficie,
            borderRadius: BorderRadius.circular(AppTheme.radio),
            border: Border.all(color: color, width: seleccionada ? 5 : 3),
            boxShadow: [
              BoxShadow(
                color: arriba ? const Color(0x40000000) : suave(color),
                blurRadius: arriba ? 12 : 0,
                offset: Offset(0, arriba ? 10 : 5),
              ),
            ],
          ),
          // Ancho fijo pero alto libre: el texto completo siempre cabe,
          // aunque ocupe varias líneas o el teléfono use letra grande.
          child: ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 150)
                .copyWith(minHeight: 124),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Dibujo(elemento.emoji, tamano: 46),
                  const SizedBox(height: 6),
                  Text(
                    elemento.texto,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.texto,
                    ),
                  ),
                ],
              ),
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
        feedback: Material(
          type: MaterialType.transparency,
          child: Transform.rotate(
            angle: -0.06,
            child: Transform.scale(scale: 1.1, child: _tarjeta(levantada: true)),
          ),
        ),
        childWhenDragging: _tarjeta(opacidad: 0.3),
        child: GestureDetector(onTap: onTap, child: _tarjeta()),
      ),
    );
  }
}

class _CanastaDestino extends StatelessWidget {
  final GrupoClasifica grupo;
  final Color color;
  final List<ElementoVisual> contenido;
  final bool fallo;
  final bool hayTarjetaElegida;
  final ValueChanged<int> onSoltar;
  final VoidCallback onTap;

  const _CanastaDestino({
    required this.grupo,
    required this.color,
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
        final borde = fallo ? AppTheme.ambar : color;

        return Semantics(
          button: true,
          label: grupo.elemento.texto,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            // Con una tarjeta encima, la canasta crece un poco para invitar
            // a soltarla.
            child: AnimatedScale(
              scale: encima ? 1.06 : 1,
              duration: const Duration(milliseconds: 150),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                constraints: const BoxConstraints(minHeight: 190),
                decoration: BoxDecoration(
                  color: fallo ? AppTheme.ambarSuave : suave(color),
                  borderRadius: BorderRadius.circular(AppTheme.radio),
                  border: Border.all(
                    color: borde,
                    width: encima || hayTarjetaElegida ? 5 : 3,
                  ),
                  boxShadow: [
                    BoxShadow(color: relieve(borde), offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  children: [
                    // Encabezado de color con el nombre de la canasta.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                      decoration: BoxDecoration(
                        color: borde,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppTheme.radio - 4),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Dibujo(grupo.elemento.emoji, tamano: 34),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            grupo.elemento.texto,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final elemento in contenido)
                            Aparecer(
                              key: ValueKey(elemento),
                              child: Dibujo(elemento.emoji, tamano: 32),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
