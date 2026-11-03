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

  /// Para niños que empiezan a leer (primero y segundo): la voz lee las
  /// opciones, los dibujos van en grande y cada tarjeta tiene su 🔊.
  final bool lecturaAsistida;

  const JuegoBase({
    super.key,
    required this.onResponder,
    required this.onCompletado,
    required this.random,
    required this.pausa,
    this.moduloId,
    this.lecturaAsistida = false,
  });
}

mixin EstadoJuego<T extends JuegoBase> on State<T> {
  int _turnoLectura = 0;

  LectorVoz get voz => VozScope.de(context);

  /// Lee [textos] uno tras otro. [alLeer] recibe cuál se está leyendo, para
  /// resaltarlo, y null al terminar. Se corta si se vuelve a llamar o con
  /// [cortarLectura] (por ejemplo, cuando el niño responde).
  Future<void> leerEnOrden(
    List<String> textos,
    ValueChanged<int?> alLeer,
  ) async {
    final turno = ++_turnoLectura;

    for (var i = 0; i < textos.length; i++) {
      if (!mounted || turno != _turnoLectura) {
        return;
      }
      alLeer(i);
      await voz.hablar(textos[i]);
    }

    if (mounted && turno == _turnoLectura) {
      alLeer(null);
    }
  }

  void cortarLectura() => _turnoLectura++;

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
