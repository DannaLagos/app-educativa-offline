import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/etiqueta.dart';
import '../../domain/estado_descarga.dart';

/// Muestra el estado de descarga de un módulo como etiqueta con color,
/// ícono y texto, para que no dependa solo del color.
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

  static Color fondo(EstadoDescarga estado) {
    switch (estado) {
      case EstadoDescarga.noDescargado:
        return AppTheme.grisSuave;
      case EstadoDescarga.descargando:
        return AppTheme.azulClaro;
      case EstadoDescarga.descargado:
        return AppTheme.verdeSuave;
      case EstadoDescarga.error:
        return AppTheme.rojoSuave;
    }
  }

  @override
  Widget build(BuildContext context) {
    final etiqueta = Etiqueta(
      texto: texto(estado, progreso),
      color: color(estado),
      fondo: fondo(estado),
      icono: icono(estado),
      grande: grande,
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
            minHeight: 14,
          ),
        ),
      ],
    );
  }
}
