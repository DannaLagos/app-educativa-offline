import 'package:flutter/widgets.dart';

import 'progreso_controller.dart';

class ProgresoScope extends InheritedNotifier<ProgresoController> {
  const ProgresoScope({
    super.key,
    required ProgresoController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Devuelve el controlador y reconstruye el widget cuando cambia el
  /// progreso (para pantallas que lo muestran, como en la HU09).
  static ProgresoController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ProgresoScope>();
    assert(scope != null, 'No hay un ProgresoScope en el árbol de widgets.');

    return scope!.notifier!;
  }

  /// Como [of], pero devuelve null si no hay ProgresoScope.
  static ProgresoController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ProgresoScope>()
        ?.notifier;
  }

  /// Devuelve el controlador sin escuchar cambios, o null si no hay
  /// ProgresoScope (por ejemplo, en pruebas de una sola pantalla).
  static ProgresoController? leer(BuildContext context) {
    return context.getInheritedWidgetOfExactType<ProgresoScope>()?.notifier;
  }
}
