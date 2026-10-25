import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/actividad.dart';

enum EstadoTarjeta { normal, seleccionada, correcta, incorrecta, deshabilitada }

/// Tarjeta grande y fácil de tocar con un dibujo (emoji) y su texto.
class TarjetaElemento extends StatelessWidget {
  final ElementoVisual elemento;
  final EstadoTarjeta estado;
  final VoidCallback? onTap;
  final double tamanoEmoji;
  final bool esCompacta;

  const TarjetaElemento({
    super.key,
    required this.elemento,
    this.estado = EstadoTarjeta.normal,
    this.onTap,
    this.tamanoEmoji = 44,
    this.esCompacta = false,
  });

  Color get _fondo => switch (estado) {
        EstadoTarjeta.normal => AppTheme.superficie,
        EstadoTarjeta.seleccionada => AppTheme.azulClaro,
        EstadoTarjeta.correcta => AppTheme.verdeSuave,
        EstadoTarjeta.incorrecta => AppTheme.ambarSuave,
        EstadoTarjeta.deshabilitada => AppTheme.grisSuave,
      };

  Color get _borde => switch (estado) {
        EstadoTarjeta.normal => AppTheme.borde,
        EstadoTarjeta.seleccionada => AppTheme.azul,
        EstadoTarjeta.correcta => AppTheme.verde,
        EstadoTarjeta.incorrecta => AppTheme.ambar,
        EstadoTarjeta.deshabilitada => AppTheme.borde,
      };

  IconData? get _marca => switch (estado) {
        EstadoTarjeta.correcta => Icons.check_circle_rounded,
        EstadoTarjeta.incorrecta => Icons.replay_circle_filled_rounded,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final marca = _marca;
    final habilitada = onTap != null && estado != EstadoTarjeta.deshabilitada;

    return Semantics(
      button: true,
      enabled: habilitada,
      label: elemento.texto,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _fondo,
          borderRadius: BorderRadius.circular(AppTheme.radio),
          border: Border.all(
            color: _borde,
            width: estado == EstadoTarjeta.normal ? 2 : 3,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radio),
            onTap: habilitada ? onTap : null,
            child: Padding(
              padding: EdgeInsets.all(esCompacta ? 10 : 14),
              child: Opacity(
                opacity: estado == EstadoTarjeta.deshabilitada ? 0.45 : 1,
                child: Row(
                  children: [
                    Text(
                      elemento.emoji,
                      style: TextStyle(fontSize: tamanoEmoji),
                    ),
                    SizedBox(width: esCompacta ? 8 : 14),
                    Expanded(
                      child: Text(
                        elemento.texto,
                        style: TextStyle(
                          fontSize: esCompacta ? 17 : 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.texto,
                        ),
                      ),
                    ),
                    if (marca != null) Icon(marca, color: _borde, size: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
          color: esAcierto ? AppTheme.verdeSuave : AppTheme.ambarSuave,
          borderRadius: BorderRadius.circular(AppTheme.radio),
          border: Border.all(color: color, width: 3),
        ),
        child: Text(
          mensaje,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Puntos que muestran cuánto falta para terminar (por ejemplo, la pregunta
/// 2 de 4).
class IndicadorAvance extends StatelessWidget {
  final int actual;
  final int total;

  const IndicadorAvance({
    super.key,
    required this.actual,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$actual de $total',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var indice = 0; indice < total; indice++)
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: indice < actual ? AppTheme.verdeVivo : AppTheme.borde,
              ),
            ),
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
