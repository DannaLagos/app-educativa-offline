import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/estado_descarga.dart';
import '../../domain/modulo.dart';
import 'estado_descarga_chip.dart';

class ModuloCard extends StatelessWidget {
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
      (estado == EstadoDescarga.noDescargado ||
          estado == EstadoDescarga.error);

  bool get _debeAvisarActualizacion =>
      modulo.tieneActualizacion && estado == EstadoDescarga.descargado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radio),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: _construirContenido(),
          ),
        ),
      ),
    );
  }

  Widget _construirContenido() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          modulo.nombre,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          modulo.areaYGrado,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textoSecundario,
          ),
        ),
        const SizedBox(height: 10),
        EstadoDescargaChip(estado: estado, progreso: progreso),
        if (estado == EstadoDescarga.descargando) ...[
          const SizedBox(height: 10),
          BarraProgresoDescarga(progreso: progreso),
        ],
        if (_debeAvisarActualizacion) ...[
          const SizedBox(height: 8),
          const _AvisoVersionNueva(),
        ],
        const SizedBox(height: 14),
        _construirAcciones(),
      ],
    );
  }

  Widget _construirAcciones() {
    return Row(
      children: [
        Expanded(child: _BotonVerDetalles(onPressed: onTap)),
        if (_puedeDescargar) ...[
          const SizedBox(width: 10),
          _BotonDescargar(nombreModulo: modulo.nombre, onPressed: onDescargar),
        ],
      ],
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
  final VoidCallback onPressed;

  const _BotonVerDetalles({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: AppTheme.grisSuave,
        foregroundColor: AppTheme.texto,
        minimumSize: const Size(48, AppTheme.alturaBotonTarjeta),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radioBoton),
        ),
      ),
      child: const Text('Ver detalles'),
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
        backgroundColor: AppTheme.azulClaro,
        foregroundColor: AppTheme.azul,
        minimumSize: const Size.square(AppTheme.alturaBotonTarjeta),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radioBoton),
        ),
      ),
      icon: const Icon(Icons.download_rounded, size: 28),
    );
  }
}
