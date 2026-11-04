import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Botón grande "de juguete": tiene un borde inferior que le da relieve y se
/// hunde al presionarlo, así el niño sabe que lo tocó.
class BotonGrande extends StatefulWidget {
  static const double _altura = 64;
  static const double _profundidad = 6;
  static const double _tamanoIcono = 30;
  static const double _grosorContorno = 3;

  /// Por debajo de este ancho (sin el relleno) solo se muestra el texto.
  static const double _anchoConIcono = 120;

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
  State<BotonGrande> createState() => _BotonGrandeState();
}

class _BotonGrandeState extends State<BotonGrande> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    final activo = widget.onPressed != null;
    final base = activo ? (widget.color ?? AppTheme.azul) : AppTheme.gris;
    final relieve = Color.lerp(base, Colors.black, 0.35)!;
    final fondo = widget.tieneContorno ? AppTheme.superficie : base;
    final colorTexto = widget.tieneContorno ? base : Colors.white;
    final hundido = _presionado ? BotonGrande._profundidad : 0.0;
    final radio = BorderRadius.circular(AppTheme.radioBoton);

    return Padding(
      padding: const EdgeInsets.only(bottom: BotonGrande._profundidad),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: double.infinity,
        height: BotonGrande._altura,
        transform: Matrix4.translationValues(0, hundido, 0),
        decoration: BoxDecoration(
          color: activo ? fondo : AppTheme.grisSuave,
          borderRadius: radio,
          border: widget.tieneContorno
              ? Border.all(color: base, width: BotonGrande._grosorContorno)
              : null,
          boxShadow: [
            BoxShadow(
              color: widget.tieneContorno ? base : relieve,
              offset: Offset(0, BotonGrande._profundidad - hundido),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radio,
            onTap: widget.onPressed,
            onHighlightChanged: (valor) => setState(() => _presionado = valor),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // Muy angosto (medio ancho con letra grande): el ícono es
              // decorativo y se quita para que el texto quepa.
              child: LayoutBuilder(
                builder: (context, espacio) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (espacio.maxWidth >= BotonGrande._anchoConIcono) ...[
                      Icon(
                        widget.icono,
                        size: BotonGrande._tamanoIcono,
                        color: activo ? colorTexto : AppTheme.gris,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        widget.texto,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: activo ? colorTexto : AppTheme.gris,
                        ),
                      ),
                    ),
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
