import 'package:flutter/widgets.dart';

import '../domain/mascota.dart';

/// La mascota del estudiante, para todas las pantallas (también los juegos,
/// que se abren como rutas nuevas y no ven el perfil). Se pone encima de
/// MaterialApp; el perfil la actualiza al abrirse o al elegirla.
class MascotaScope extends InheritedNotifier<ValueNotifier<MascotaElegida?>> {
  const MascotaScope({
    super.key,
    required ValueNotifier<MascotaElegida?> mascota,
    required super.child,
  }) : super(notifier: mascota);

  /// La mascota elegida, o null si no hay (por ejemplo, en pruebas).
  static MascotaElegida? de(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MascotaScope>()
        ?.notifier
        ?.value;
  }

  /// La mascota elegida sin escuchar cambios (para usar fuera de build).
  static MascotaElegida? leer(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<MascotaScope>()
        ?.notifier
        ?.value;
  }

  /// Cambia la mascota sin escuchar cambios. No hace nada si no hay scope.
  static void cambiar(BuildContext context, MascotaElegida? mascota) {
    final notificador =
        context.getInheritedWidgetOfExactType<MascotaScope>()?.notifier;

    if (notificador != null) {
      notificador.value = mascota;
    }
  }
}
