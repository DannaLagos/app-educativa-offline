import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

void mostrarAvisoResultado(
  ScaffoldMessengerState mensajero, {
  required bool fueExitoso,
  required String mensaje,
}) {
  mensajero.showSnackBar(
    SnackBar(
      backgroundColor: fueExitoso ? AppTheme.verde : AppTheme.rojo,
      content: Text(
        mensaje,
        style: const TextStyle(fontSize: 18),
      ),
    ),
  );
}
