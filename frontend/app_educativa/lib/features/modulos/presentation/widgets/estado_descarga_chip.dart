import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/estado_descarga.dart';

/// Muestra el estado de descarga de un módulo con color, ícono y texto,
/// para que no dependa solo del color.
class EstadoDescargaChip extends StatelessWidget {
  final EstadoDescarga estado;

  /// Avance entre 0 y 1; solo se usa mientras se descarga.
  final double? progreso;

  /// Versión grande para el detalle (con barra de progreso).
  final bool grande;

  const EstadoDescargaChip({
    super.key,
    required this.estado,
    this.progreso,
    this.grande = false,
  });

  static String texto(EstadoDescarga estado, double? progreso) {
    switch (estado) {
      case EstadoDescarga.noDescargado:
        return 'No descargado';
      case EstadoDescarga.descargando:
        final porcentaje = ((progreso ?? 0) * 100).round();
        return 'Descargando $porcentaje %';
      case EstadoDescarga.descargado:
        return 'Descargado';
      case EstadoDescarga.error:
        return 'Error en la descarga';
    }
  }

  static Color color(EstadoDescarga estado) {
    switch (estado) {
      case EstadoDescarga.noDescargado:
        return AppTheme.gris;
      case EstadoDescarga.descargando:
        return AppTheme.azul;
      case EstadoDescarga.descargado:
        return AppTheme.verde;
      case EstadoDescarga.error:
        return AppTheme.rojo;
    }
  }

  static IconData icono(EstadoDescarga estado) {
    switch (estado) {
      case EstadoDescarga.noDescargado:
        return Icons.cloud_download_outlined;
      case EstadoDescarga.descargando:
        return Icons.downloading_rounded;
      case EstadoDescarga.descargado:
        return Icons.offline_pin_rounded;
      case EstadoDescarga.error:
        return Icons.error_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fondo = color(estado);

    final etiqueta = Container(
      padding: EdgeInsets.symmetric(
        horizontal: grande ? 16 : 10,
        vertical: grande ? 12 : 6,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(grande ? 16 : 12),
      ),
      child: Row(
        mainAxisSize: grande ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(
            icono(estado),
            color: Colors.white,
            size: grande ? 30 : 20,
          ),
          SizedBox(width: grande ? 12 : 6),
          Flexible(
            child: Text(
              texto(estado, progreso),
              style: TextStyle(
                color: Colors.white,
                fontSize: grande ? 20 : 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (!grande || estado != EstadoDescarga.descargando) {
      return etiqueta;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        etiqueta,
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progreso,
            minHeight: 16,
            color: AppTheme.azul,
            backgroundColor: const Color(0xFFBBDEFB),
          ),
        ),
      ],
    );
  }
}
