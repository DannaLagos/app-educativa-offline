import 'package:flutter/material.dart';

class MensajeConAccion extends StatelessWidget {
  static const double _tamanoIcono = 72;

  final Icon icono;
  final String mensaje;
  final Widget accion;

  const MensajeConAccion({
    super.key,
    required this.icono,
    required this.mensaje,
    required this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme.merge(
              data: const IconThemeData(size: _tamanoIcono),
              child: icono,
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 24),
            accion,
          ],
        ),
      ),
    );
  }
}
