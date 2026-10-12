import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Etiqueta tipo píldora del diseño (área, grado, estado). Usa texto oscuro
/// sobre fondo suave para mantener el contraste AA.
class Etiqueta extends StatelessWidget {
  final String texto;
  final Color color;
  final Color fondo;
  final IconData? icono;
  final bool grande;

  const Etiqueta({
    super.key,
    required this.texto,
    required this.color,
    required this.fondo,
    this.icono,
    this.grande = false,
  });

  const Etiqueta.azul(this.texto, {super.key, this.icono, this.grande = false})
      : color = AppTheme.azul,
        fondo = AppTheme.azulClaro;

  const Etiqueta.gris(this.texto, {super.key, this.icono, this.grande = false})
      : color = AppTheme.gris,
        fondo = AppTheme.grisSuave;

  @override
  Widget build(BuildContext context) {
    final tamanoTexto = grande ? 18.0 : 14.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: grande ? 14 : 10,
        vertical: grande ? 10 : 5,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(grande ? 14 : 999),
      ),
      child: Row(
        mainAxisSize: grande ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, color: color, size: grande ? 26 : 17),
            SizedBox(width: grande ? 10 : 5),
          ],
          Flexible(
            child: Text(
              texto,
              style: TextStyle(
                color: color,
                fontSize: tamanoTexto,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
