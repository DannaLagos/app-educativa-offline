import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/dibujo.dart';
import '../../domain/estado_descarga.dart';
import '../../domain/modulo.dart';
import 'estado_descarga_chip.dart';
import 'icono_area.dart';

/// Un módulo como ficha de juego: "portada" con el color y la ilustración
/// de su materia, su estado de descarga y botones grandes.
class ModuloCard extends StatelessWidget {
  static const double _relieve = 5;

  final Modulo modulo;
  final EstadoDescarga estado;
  final double? progreso;
  final VoidCallback onTap;
  final VoidCallback? onDescargar;

  const ModuloCard({
    super.key,
    required this.modulo,
    required this.estado,
    required this.onTap,
    this.progreso,
    this.onDescargar,
  });

  bool get _puedeDescargar =>
      onDescargar != null &&
      (estado == EstadoDescarga.noDescargado || estado == EstadoDescarga.error);

  bool get _debeAvisarActualizacion =>
      modulo.tieneActualizacion && estado == EstadoDescarga.descargado;

  @override
  Widget build(BuildContext context) {
    final apariencia = AparienciaArea.de(modulo.area);
    final radio = BorderRadius.circular(24);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14 + _relieve),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.superficie,
          borderRadius: radio,
          border: Border.all(
            color: Color.lerp(apariencia.color, Colors.white, 0.6)!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Color.lerp(apariencia.color, Colors.white, 0.45)!,
              offset: const Offset(0, _relieve),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radio,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _construirContenido(apariencia),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirContenido(AparienciaArea apariencia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Portada(apariencia: apariencia, grado: modulo.grado),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modulo.nombre,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    modulo.areaYGrado,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 8),
                  EstadoDescargaChip(estado: estado, progreso: progreso),
                ],
              ),
            ),
          ],
        ),
        if (estado == EstadoDescarga.descargando) ...[
          const SizedBox(height: 10),
          BarraProgresoDescarga(progreso: progreso),
        ],
        if (_debeAvisarActualizacion) ...[
          const SizedBox(height: 8),
          const _AvisoVersionNueva(),
        ],
        const SizedBox(height: 12),
        _construirAcciones(apariencia.color),
      ],
    );
  }

  Widget _construirAcciones(Color color) {
    return Row(
      children: [
        Expanded(child: _BotonVerDetalles(color: color, onPressed: onTap)),
        if (_puedeDescargar) ...[
          const SizedBox(width: 10),
          _BotonDescargar(nombreModulo: modulo.nombre, onPressed: onDescargar),
        ],
      ],
    );
  }
}

/// Cuadro de color con la ilustración de la materia y el grado.
class _Portada extends StatelessWidget {
  static const double _tamano = 84;

  final AparienciaArea apariencia;
  final int grado;

  const _Portada({required this.apariencia, required this.grado});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _tamano,
      height: _tamano,
      decoration: BoxDecoration(
        color: apariencia.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Dibujo(apariencia.emoji, tamano: 50),
          Positioned(
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$grado°',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: apariencia.color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoVersionNueva extends StatelessWidget {
  const _AvisoVersionNueva();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.system_update_rounded, size: 20, color: AppTheme.azul),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Hay una versión nueva',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.azul,
            ),
          ),
        ),
      ],
    );
  }
}

class _BotonVerDetalles extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;

  const _BotonVerDetalles({required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, AppTheme.alturaBotonTarjeta),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radioBoton),
        ),
      ),
      icon: const Icon(Icons.play_arrow_rounded, size: 28),
      label: const Text('Ver detalles'),
    );
  }
}

class _BotonDescargar extends StatelessWidget {
  final String nombreModulo;
  final VoidCallback? onPressed;

  const _BotonDescargar({
    required this.nombreModulo,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: 'Descargar $nombreModulo',
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppTheme.amarillo,
        foregroundColor: const Color(0xFF5C3A00),
        minimumSize: const Size.square(AppTheme.alturaBotonTarjeta),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radioBoton),
        ),
      ),
      icon: const Icon(Icons.download_rounded, size: 30),
    );
  }
}
