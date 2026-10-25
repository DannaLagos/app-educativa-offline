import 'package:flutter/material.dart';

class BotonGrande extends StatelessWidget {
  static const double _altura = 64;
  static const double _tamanoIcono = 28;
  static const double _grosorContorno = 2;

  final String texto;
  final IconData icono;
  final VoidCallback? onPressed;
  final Color? color;
  final bool tieneContorno;

  const BotonGrande({
    super.key,
    required this.texto,
    required this.icono,
    required this.onPressed,
    this.color,
    this.tieneContorno = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _altura,
      child: tieneContorno ? _construirConContorno() : _construirRelleno(),
    );
  }

  Widget _construirConContorno() {
    final colorElegido = color;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icono, size: _tamanoIcono),
      label: Text(texto),
      style: colorElegido == null
          ? null
          : OutlinedButton.styleFrom(
              foregroundColor: colorElegido,
              side: BorderSide(color: colorElegido, width: _grosorContorno),
            ),
    );
  }

  Widget _construirRelleno() {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icono, size: _tamanoIcono),
      label: Text(texto),
      style: color == null
          ? null
          : ElevatedButton.styleFrom(backgroundColor: color),
    );
  }
}
