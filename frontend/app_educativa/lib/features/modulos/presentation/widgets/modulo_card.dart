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

  const ModuloCard({
    super.key,
    required this.modulo,
    required this.estado,
    required this.onTap,
    this.progreso,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF90A4AE)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 30,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modulo.nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
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
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
