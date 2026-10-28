import 'package:flutter/widgets.dart';

import 'sincronizacion_controller.dart';

class SincronizacionScope extends InheritedNotifier<SincronizacionController> {
  const SincronizacionScope({
    super.key,
    required SincronizacionController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Devuelve el controlador y reconstruye el widget cuando cambia la
  /// conexión o la sincronización; null si no hay SincronizacionScope (por
  /// ejemplo, en pruebas de una sola pantalla).
  static SincronizacionController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SincronizacionScope>()
        ?.notifier;
  }
}
