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

  /// Si se indica, muestra un botón para descargar sin entrar al detalle
  /// (solo cuando el módulo no está descargado ni descargándose).
  final VoidCallback? onDescargar;

  const ModuloCard({
    super.key,
    required this.modulo,
    required this.estado,
    required this.onTap,
    this.progreso,
    this.onDescargar,
  });

  @override
  Widget build(BuildContext context) {
    final puedeDescargar = onDescargar != null &&
        (estado == EstadoDescarga.noDescargado ||
            estado == EstadoDescarga.error);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radio),
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                const SizedBox(height: 4),
                Text(
                  '${modulo.area} · Grado ${modulo.grado}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textoSecundario,
                  ),
                ),
                const SizedBox(height: 10),
                EstadoDescargaChip(
                  estado: estado,
                  progreso: progreso,
                ),
                if (estado == EstadoDescarga.descargando) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progreso,
                      minHeight: 8,
                    ),
                  ),
                ],
                if (modulo.tieneActualizacion &&
                    estado == EstadoDescarga.descargado) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(
                        Icons.system_update_rounded,
                        size: 20,
                        color: AppTheme.azul,
                      ),
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
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: onTap,
                        style: TextButton.styleFrom(
                          backgroundColor: AppTheme.grisSuave,
                          foregroundColor: AppTheme.texto,
                          minimumSize: const Size(48, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Ver detalles'),
                      ),
                    ),
                    if (puedeDescargar) ...[
                      const SizedBox(width: 10),
                      IconButton.filled(
                        tooltip: 'Descargar ${modulo.nombre}',
                        onPressed: onDescargar,
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.azulClaro,
                          foregroundColor: AppTheme.azul,
                          minimumSize: const Size(52, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 28),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
