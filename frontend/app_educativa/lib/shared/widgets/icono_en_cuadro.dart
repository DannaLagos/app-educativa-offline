import 'package:flutter/material.dart';

class IconoEnCuadro extends StatelessWidget {
  static const double _proporcionRadio = 0.28;
  static const double _proporcionIcono = 0.55;

  final IconData icono;
  final ({Color icono, Color fondo}) colores;
  final double tamano;

  const IconoEnCuadro({
    super.key,
    required this.icono,
    required this.colores,
    required this.tamano,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: colores.fondo,
        borderRadius: BorderRadius.circular(tamano * _proporcionRadio),
      ),
      child: Icon(
        icono,
        color: colores.icono,
        size: tamano * _proporcionIcono,
      ),
    );
  }
}
