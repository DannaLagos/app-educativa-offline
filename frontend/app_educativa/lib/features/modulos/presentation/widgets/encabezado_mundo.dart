import 'package:flutter/material.dart';

import '../../../../shared/widgets/dibujo.dart';
import 'icono_area.dart';

/// Encabezado grande con el color y la ilustración de la materia, como el
/// escenario de la mascota en el inicio. Se usa al entrar a un mundo y en
/// el detalle de un módulo.
class EncabezadoMundo extends StatelessWidget {
  static const double _tamanoDibujo = 96;

  /// Materia: de ella salen el color y la ilustración.
  final String area;
  final String titulo;
  final String? subtitulo;

  /// Datos cortos en pastillas blancas (por ejemplo, "Grado 1").
  final List<String> etiquetas;

  /// Acción principal debajo (opcional).
  final Widget? accion;

  /// Para pantallas que no son de una materia (por ejemplo, Descargas):
  /// reemplazan el color y la ilustración de [area].
  final Color? color;
  final String? emoji;

  /// A la derecha del título (por ejemplo, un botón 🔊).
  final Widget? extremo;

  const EncabezadoMundo({
    super.key,
    required this.area,
    required this.titulo,
    this.subtitulo,
    this.etiquetas = const [],
    this.accion,
    this.color,
    this.emoji,
    this.extremo,
  });

  @override
  Widget build(BuildContext context) {
    final apariencia = AparienciaArea.de(area);
    final color = this.color ?? apariencia.color;
    final detalle = subtitulo;
    final boton = accion;
    final alLado = extremo;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Más oscuro abajo, no más claro: el texto blanco sigue legible.
          colors: [color, Color.lerp(color, Colors.black, 0.12)!],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(color, Colors.black, 0.35)!,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: CustomPaint(
          painter: const _PintorBurbujas(),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: _tamanoDibujo,
                      height: _tamanoDibujo,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Dibujo(emoji ?? apariencia.emoji, tamano: 64),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              fontSize: 26,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          if (detalle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              detalle,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                          if (etiquetas.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final etiqueta in etiquetas)
                                  _Pastilla(texto: etiqueta, color: color),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (alLado != null) ...[const SizedBox(width: 8), alLado],
                  ],
                ),
                if (boton != null) ...[
                  const SizedBox(height: 18),
                  boton,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pastilla extends StatelessWidget {
  final String texto;
  final Color color;

  const _Pastilla({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

/// Burbujas claras de fondo, como en el escenario de la mascota.
class _PintorBurbujas extends CustomPainter {
  const _PintorBurbujas();

  @override
  void paint(Canvas canvas, Size size) {
    final burbuja = Paint()..color = const Color(0x1AFFFFFF);

    canvas.drawCircle(
        Offset(size.width * 0.92, size.height * 0.1), 64, burbuja);
    canvas.drawCircle(
        Offset(size.width * 0.7, size.height * 1.05), 50, burbuja);
    canvas.drawCircle(
        Offset(size.width * 0.02, size.height * 0.95), 40, burbuja);
  }

  @override
  bool shouldRepaint(_PintorBurbujas anterior) => false;
}
