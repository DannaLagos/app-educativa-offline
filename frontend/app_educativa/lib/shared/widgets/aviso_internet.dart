import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'boton_escuchar.dart';

/// Advertencia de que los módulos solo se descargan con internet.
class AvisoInternet extends StatelessWidget {
  final String titulo;
  final String detalle;

  /// Al inicio de la app: explica que hace falta internet para descargar.
  const AvisoInternet.paraDescargar({super.key})
      : titulo = 'Necesitas internet para descargar los módulos',
        detalle = 'Descárgalos una vez con conexión y después podrás leer y '
            'jugar sin internet.';

  /// En el inicio, cuando el dispositivo no tiene conexión.
  const AvisoInternet.sinConexion({super.key})
      : titulo = 'Estás sin internet',
        detalle = 'Puedes usar los módulos que ya descargaste. Para '
            'descargar módulos nuevos, conéctate a internet.';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Container(
        key: const ValueKey('aviso-internet'),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: AppTheme.azulSuave,
          borderRadius: BorderRadius.circular(AppTheme.radio),
          border: Border.all(color: AppTheme.azul, width: 2),
        ),
        child: Row(
          children: [
            const Text('📶', style: TextStyle(fontSize: 34)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.azul,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detalle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.texto,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            BotonEscuchar(texto: '$titulo. $detalle', color: AppTheme.azul),
          ],
        ),
      ),
    );
  }
}
