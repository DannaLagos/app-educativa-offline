import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ConfirmarEliminarDialog extends StatelessWidget {
  final String nombreModulo;

  const ConfirmarEliminarDialog({
    super.key,
    required this.nombreModulo,
  });

  static Future<bool> mostrar(BuildContext context, String nombreModulo) async {
    final fueConfirmado = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmarEliminarDialog(nombreModulo: nombreModulo),
    );

    return fueConfirmado ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.delete_forever_rounded,
        size: 48,
        color: AppTheme.rojo,
      ),
      title: Text(
        '¿Eliminar "$nombreModulo"?',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: const Text(
        'Se borrará de este dispositivo y necesitarás internet para '
        'volver a descargarlo. Tu progreso no se pierde.',
        style: TextStyle(fontSize: 18),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rojo),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}
