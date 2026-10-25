import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class Etiqueta extends StatelessWidget {
  static const double _radioPildora = 999;

  final String texto;
  final Color color;
  final Color fondo;
  final IconData? icono;
  final bool esGrande;

  const Etiqueta({
    super.key,
    required this.texto,
    required this.color,
    required this.fondo,
    this.icono,
    this.esGrande = false,
  });

  const Etiqueta.azul(this.texto, {super.key, this.icono, this.esGrande = false})
      : color = AppTheme.azul,
        fondo = AppTheme.azulClaro;

  const Etiqueta.gris(this.texto, {super.key, this.icono, this.esGrande = false})
      : color = AppTheme.gris,
        fondo = AppTheme.grisSuave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: esGrande ? 14 : 10,
        vertical: esGrande ? 10 : 5,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(esGrande ? 14 : _radioPildora),
      ),
      child: Row(
        mainAxisSize: esGrande ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, color: color, size: esGrande ? 26 : 17),
            SizedBox(width: esGrande ? 10 : 5),
          ],
          Flexible(child: _construirTexto()),
        ],
      ),
    );
  }

  Widget _construirTexto() {
    return Text(
      texto,
      style: TextStyle(
        color: color,
        fontSize: esGrande ? 18 : 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
