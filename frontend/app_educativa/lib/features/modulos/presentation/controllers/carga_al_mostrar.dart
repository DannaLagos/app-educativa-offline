import 'package:flutter/widgets.dart';

import 'modulos_controller.dart';
import 'modulos_scope.dart';

// Se agenda tras el primer frame porque cargar notifica cambios durante el build.
mixin CargaAlMostrar<T extends StatefulWidget> on State<T> {
  bool _seInicioLaCarga = false;

  Future<void> cargarAlMostrar(ModulosController controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_seInicioLaCarga) {
      return;
    }

    _seInicioLaCarga = true;
    final controller = ModulosScope.of(context);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => cargarAlMostrar(controller),
    );
  }
}
