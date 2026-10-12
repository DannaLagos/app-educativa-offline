import 'package:flutter/widgets.dart';

import 'modulos_controller.dart';

/// Hace disponible el [ModulosController] a todas las pantallas y las
/// reconstruye cuando cambia.
class ModulosScope extends InheritedNotifier<ModulosController> {
  const ModulosScope({
    super.key,
    required ModulosController controller,
    required super.child,
  }) : super(notifier: controller);

  static ModulosController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ModulosScope>();
    assert(scope != null, 'No hay un ModulosScope en el árbol de widgets.');

    return scope!.notifier!;
  }
}
