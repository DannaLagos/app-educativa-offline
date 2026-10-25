import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/etiqueta.dart';
import '../../domain/estado_descarga.dart';

class EstadoDescargaChip extends StatelessWidget {
  final EstadoDescarga estado;
  final double? progreso;
  final bool esGrande;

  const EstadoDescargaChip({
    super.key,
    required this.estado,
    this.progreso,
    this.esGrande = false,
  });

  @override
  Widget build(BuildContext context) {
    final etiqueta = Etiqueta(
      texto: estado.describir(progreso),
      color: estado.color,
      fondo: estado.fondo,
      icono: estado.icono,
      esGrande: esGrande,
    );

    if (!esGrande || estado != EstadoDescarga.descargando) {
      return etiqueta;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        etiqueta,
        const SizedBox(height: 12),
        BarraProgresoDescarga(progreso: progreso, esGruesa: true),
      ],
    );
  }
}

class BarraProgresoDescarga extends StatelessWidget {
  final double? progreso;
  final bool esGruesa;

  const BarraProgresoDescarga({
    super.key,
    required this.progreso,
    this.esGruesa = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(esGruesa ? 8 : 6),
      child: LinearProgressIndicator(
        value: progreso,
        minHeight: esGruesa ? 14 : 8,
      ),
    );
  }
}

extension AparienciaEstadoDescarga on EstadoDescarga {
  static const int _porcentajeCompleto = 100;

  String describir(double? progreso) {
    switch (this) {
      case EstadoDescarga.noDescargado:
        return 'No descargado';
      case EstadoDescarga.descargando:
        final porcentaje = ((progreso ?? 0) * _porcentajeCompleto).round();
        return 'Descargando $porcentaje %';
      case EstadoDescarga.descargado:
        return 'Descargado';
      case EstadoDescarga.error:
        return 'Error en la descarga';
    }
  }

  Color get color {
    switch (this) {
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

  Color get fondo {
    switch (this) {
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

  IconData get icono {
    switch (this) {
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
}
