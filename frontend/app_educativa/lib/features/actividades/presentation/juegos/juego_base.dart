import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../../../core/voz/lector_voz.dart';

/// Lo que todos los juegos reciben de la pantalla del juego.
abstract class JuegoBase extends StatefulWidget {
  /// Se llama con cada respuesta, para mostrar la retroalimentación y
  /// contar los errores.
  final ValueChanged<bool> onResponder;

  /// Se llama cuando el niño termina el juego.
  final VoidCallback onCompletado;

  /// Para mezclar opciones y tarjetas (en pruebas se usa una semilla fija).
  final Random random;

  /// Tiempo para ver la respuesta correcta antes de pasar a la siguiente.
  final Duration pausa;

  /// Módulo al que pertenece el juego (para abrir la cartilla desde una
  /// pista).
  final String? moduloId;

  const JuegoBase({
    super.key,
    required this.onResponder,
    required this.onCompletado,
    required this.random,
    required this.pausa,
    this.moduloId,
  });
}

mixin EstadoJuego<T extends JuegoBase> on State<T> {
  LectorVoz get voz => VozScope.de(context);

  /// Espera [JuegoBase.pausa] y ejecuta [accion] si la pantalla sigue abierta.
  void despuesDeLaPausa(VoidCallback accion) {
    Future<void>.delayed(widget.pausa, () {
      if (mounted) {
        accion();
      }
    });
  }

  List<int> indicesMezclados(int cantidad) {
    return List<int>.generate(cantidad, (indice) => indice)
      ..shuffle(widget.random);
  }
}
