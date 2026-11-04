import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/dibujo.dart';
import '../../domain/actividad.dart';
import 'efectos.dart';

enum EstadoTarjeta { normal, seleccionada, correcta, incorrecta, deshabilitada }

/// Tarjeta grande y fácil de tocar con un dibujo (emoji) y su texto. Tiene
/// relieve como un botón de juguete, rebota al acertar y se sacude al
/// fallar.
class TarjetaElemento extends StatefulWidget {
  static const double _relieve = 5;
  static const Color _resalte = Color(0xFFFFC93C);

  final ElementoVisual elemento;
  final EstadoTarjeta estado;
  final VoidCallback? onTap;
  final double tamanoEmoji;
  final bool esCompacta;

  /// Color de acento de la tarjeta (borde y círculo del dibujo). Así cada
  /// opción se distingue de las demás.
  final Color? color;

  /// La voz está leyendo esta tarjeta: se ilumina, como en karaoke.
  final bool resaltada;

  /// Si se da, la tarjeta tiene su propio botón 🔊 para volver a escucharla
  /// sin responder.
  final VoidCallback? onEscuchar;

  /// Dibujo grande arriba y texto abajo, para niños que empiezan a leer.
  final bool vertical;

  const TarjetaElemento({
    super.key,
    required this.elemento,
    this.estado = EstadoTarjeta.normal,
    this.onTap,
    this.tamanoEmoji = 44,
    this.esCompacta = false,
    this.color,
    this.resaltada = false,
    this.onEscuchar,
    this.vertical = false,
  });

  @override
  State<TarjetaElemento> createState() => _TarjetaElementoState();
}

class _TarjetaElementoState extends State<TarjetaElemento> {
  int _sacudidas = 0;
  int _rebotes = 0;

  @override
  void didUpdateWidget(TarjetaElemento anterior) {
    super.didUpdateWidget(anterior);

    if (anterior.estado == widget.estado) {
      return;
    }
    if (widget.estado == EstadoTarjeta.incorrecta) {
      _sacudidas++;
    } else if (widget.estado == EstadoTarjeta.correcta) {
      _rebotes++;
    }
  }

  Color get _acento => widget.color ?? AppTheme.azul;

  bool get _resaltada =>
      widget.resaltada && widget.estado == EstadoTarjeta.normal;

  Color get _fondo => switch (widget.estado) {
        EstadoTarjeta.normal =>
          _resaltada ? AppTheme.amarilloSuave : AppTheme.superficie,
        EstadoTarjeta.seleccionada => suave(_acento),
        EstadoTarjeta.correcta => AppTheme.verdeSuave,
        EstadoTarjeta.incorrecta => AppTheme.ambarSuave,
        EstadoTarjeta.deshabilitada => AppTheme.grisSuave,
      };

  Color get _borde => switch (widget.estado) {
        EstadoTarjeta.normal => _resaltada
            ? TarjetaElemento._resalte
            : Color.lerp(_acento, Colors.white, 0.45)!,
        EstadoTarjeta.seleccionada => _acento,
        EstadoTarjeta.correcta => AppTheme.verde,
        EstadoTarjeta.incorrecta => AppTheme.ambar,
        EstadoTarjeta.deshabilitada => AppTheme.borde,
      };

  IconData? get _marca => switch (widget.estado) {
        EstadoTarjeta.correcta => Icons.check_circle_rounded,
        EstadoTarjeta.incorrecta => Icons.replay_circle_filled_rounded,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final estado = widget.estado;
    final habilitada =
        widget.onTap != null && estado != EstadoTarjeta.deshabilitada;
    final radio = BorderRadius.circular(AppTheme.radio);

    return Semantics(
      button: true,
      enabled: habilitada,
      label: widget.elemento.texto,
      excludeSemantics: true,
      child: Sacudir(
        veces: _sacudidas,
        child: Rebotar(
          veces: _rebotes,
          child: AnimatedScale(
            scale: _resaltada ? 1.04 : 1,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(bottom: TarjetaElemento._relieve),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _fondo,
                  borderRadius: radio,
                  border: Border.all(
                    color: _borde,
                    width: estado == EstadoTarjeta.normal && !_resaltada ? 3 : 5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: estado == EstadoTarjeta.deshabilitada
                          ? AppTheme.borde
                          : Color.lerp(_borde, Colors.white, 0.3)!,
                      offset: const Offset(0, TarjetaElemento._relieve),
                    ),
                    if (_resaltada)
                      const BoxShadow(
                        color: Color(0x88FFC93C),
                        blurRadius: 16,
                      ),
                  ],
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: radio,
                    onTap: habilitada ? widget.onTap : null,
                    child: Opacity(
                      opacity: estado == EstadoTarjeta.deshabilitada ? 0.45 : 1,
                      child: widget.vertical
                          ? _construirVertical()
                          : _construirHorizontal(),
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

  Widget _circuloDibujo() {
    final estado = widget.estado;
    final circulo = widget.tamanoEmoji + (widget.esCompacta ? 14 : 22);

    return Container(
      width: circulo,
      height: circulo,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: estado == EstadoTarjeta.normal ||
                estado == EstadoTarjeta.seleccionada
            ? suave(_acento)
            : AppTheme.superficie,
        shape: BoxShape.circle,
      ),
      child: Dibujo(widget.elemento.emoji, tamano: widget.tamanoEmoji),
    );
  }

  /// La marca de acierto o error; si no hay, el botón 🔊 (si lo hay).
  Widget? _esquina() {
    final marca = _marca;
    final onEscuchar = widget.onEscuchar;

    if (marca != null) {
      return Icon(marca, color: _borde, size: 36);
    }
    if (onEscuchar != null && widget.estado != EstadoTarjeta.deshabilitada) {
      return IconButton.filledTonal(
        tooltip: 'Escuchar',
        iconSize: 26,
        onPressed: onEscuchar,
        icon: const Icon(Icons.volume_up_rounded),
      );
    }
    return null;
  }

  Widget _construirHorizontal() {
    final compacta = widget.esCompacta;
    final esquina = _esquina();

    return Padding(
      padding: EdgeInsets.all(compacta ? 8 : 12),
      child: Row(
        children: [
          _circuloDibujo(),
          SizedBox(width: compacta ? 8 : 14),
          Expanded(
            child: Text(
              widget.elemento.texto,
              style: TextStyle(
                fontSize: compacta ? 17 : 21,
                fontWeight: FontWeight.w800,
                color: AppTheme.texto,
              ),
            ),
          ),
          if (esquina != null) esquina,
        ],
      ),
    );
  }

  Widget _construirVertical() {
    final esquina = _esquina();

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: _circuloDibujo()),
              const SizedBox(height: 8),
              Text(
                widget.elemento.texto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.texto,
                ),
              ),
            ],
          ),
        ),
        if (esquina != null) Positioned(top: 2, right: 2, child: esquina),
      ],
    );
  }
}

/// Mensaje grande que aparece después de cada respuesta.
class Retroalimentacion extends StatelessWidget {
  final bool esAcierto;
  final String mensaje;

  const Retroalimentacion({
    super.key,
    required this.esAcierto,
    required this.mensaje,
  });

  @override
  Widget build(BuildContext context) {
    final color = esAcierto ? AppTheme.verde : AppTheme.ambar;

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.radio),
          boxShadow: [BoxShadow(color: relieve(color), offset: const Offset(0, 5))],
        ),
        child: Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Estrellas que se encienden a medida que el niño avanza (por ejemplo, la
/// pregunta 2 de 4).
class IndicadorAvance extends StatelessWidget {
  static const Color _encendida = Color(0xFFFFC93C);

  final int actual;
  final int total;

  const IndicadorAvance({
    super.key,
    required this.actual,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final tamano = total > 8 ? 26.0 : 34.0;

    return Semantics(
      label: '$actual de $total',
      excludeSemantics: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 2,
        children: [
          for (var indice = 0; indice < total; indice++)
            if (indice < actual)
              // Cada estrella nueva aparece con un saltito.
              Aparecer(
                key: ValueKey('estrella-$indice'),
                child: Icon(
                  Icons.star_rounded,
                  size: tamano,
                  color: _encendida,
                  shadows: const [
                    Shadow(color: Color(0x66C2410C), offset: Offset(0, 2)),
                  ],
                ),
              )
            else
              Icon(Icons.star_rounded, size: tamano, color: AppTheme.borde),
        ],
      ),
    );
  }
}

/// Fila de estrellas (de 0 a [maximo]).
class FilaEstrellas extends StatelessWidget {
  final int estrellas;
  final int maximo;
  final double tamano;

  const FilaEstrellas({
    super.key,
    required this.estrellas,
    this.maximo = 3,
    this.tamano = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$estrellas de $maximo estrellas',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var indice = 0; indice < maximo; indice++)
            Icon(
              indice < estrellas ? Icons.star_rounded : Icons.star_border_rounded,
              size: tamano,
              color: indice < estrellas
                  ? const Color(0xFFF2A900)
                  : AppTheme.textoSecundario,
            ),
        ],
      ),
    );
  }
}
