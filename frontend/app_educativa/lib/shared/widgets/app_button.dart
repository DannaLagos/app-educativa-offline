import 'package:flutter/material.dart';

/// Botón de ancho completo y 64 px de alto, fácil de tocar para niños.
class BotonGrande extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback? onPressed;
  final Color? color;
  final bool contorno;

  const BotonGrande({
    super.key,
    required this.texto,
    required this.icono,
    required this.onPressed,
    this.color,
    this.contorno = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(icono, size: 28);
    final label = Text(texto);

    return SizedBox(
      width: double.infinity,
      height: 64,
      child: contorno
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: icon,
              label: label,
              style: color == null
                  ? null
                  : OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color!, width: 2),
                    ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: icon,
              label: label,
              style: color == null
                  ? null
                  : ElevatedButton.styleFrom(backgroundColor: color),
            ),
    );
  }
}
