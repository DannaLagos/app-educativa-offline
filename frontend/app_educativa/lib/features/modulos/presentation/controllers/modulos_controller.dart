import 'package:flutter/foundation.dart';

import '../../data/modulo_repository.dart';
import '../../domain/modulo.dart';

/// Estado compartido de los módulos para la lista, el detalle y
/// "Mis descargas". La interfaz solo habla con este controlador.
class ModulosController extends ChangeNotifier {
  final ModuloRepository _repositorio;

  ModulosController({
    required ModuloRepository repositorio,
  }) : _repositorio = repositorio;

  List<Modulo> _catalogo = const [];
  bool _cargando = false;
  bool _desdeCache = false;
  bool _errorCarga = false;

  List<Modulo> get catalogo => _catalogo;
  bool get cargando => _cargando;
  bool get desdeCache => _desdeCache;
  bool get errorCarga => _errorCarga;

  Future<void> cargarCatalogo() async {
    _cargando = true;
    _errorCarga = false;
    notifyListeners();

    try {
      final resultado = await _repositorio.obtenerCatalogo();
      _catalogo = resultado.modulos;
      _desdeCache = resultado.desdeCache;
    } catch (error, stack) {
      debugPrint('Error al cargar el catálogo: $error\n$stack');
      _errorCarga = true;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Modulo? modulo(String id) {
    for (final modulo in _catalogo) {
      if (modulo.id == id) {
        return modulo;
      }
    }

    return null;
  }
}
