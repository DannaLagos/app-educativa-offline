import 'package:flutter/foundation.dart';

import '../../data/descarga_service.dart';
import '../../data/modulo_repository.dart';
import '../../domain/contenido_incompleto_exception.dart';
import '../../domain/descarga_exception.dart';
import '../../domain/estado_descarga.dart';
import '../../domain/modulo.dart';
import '../../domain/recurso_local.dart';

class ModulosController extends ChangeNotifier {
  static const String _mensajeDescargaInterrumpida =
      'La descarga anterior no terminó. Vuelve a intentarlo.';
  static const String _mensajeErrorInesperado =
      'No se pudo descargar el módulo. Vuelve a intentarlo.';
  static const String _mensajeFaltanArchivos =
      'Faltan archivos de este módulo. Descárgalo de nuevo.';
  static const int _pasosDeProgreso = 100;

  final ModuloRepository _repositorio;
  final DescargaService _descargaService;

  ModulosController({
    required ModuloRepository repositorio,
    required DescargaService descargaService,
  })  : _repositorio = repositorio,
        _descargaService = descargaService;

  List<Modulo> _catalogo = const [];
  List<Modulo> _descargados = const [];
  bool _estaCargando = false;
  bool _vieneDeCache = false;
  bool _huboErrorAlCargar = false;
  final Map<String, double> _progresoPorModulo = {};
  final Map<String, String> _errorPorModulo = {};

  List<Modulo> get catalogo => _catalogo;
  List<Modulo> get descargados => _descargados;
  bool get estaCargando => _estaCargando;
  bool get vieneDeCache => _vieneDeCache;
  bool get huboErrorAlCargar => _huboErrorAlCargar;

  Future<void> inicializar() async {
    try {
      await _descargaService.limpiarIncompletas();
    } catch (error, stack) {
      debugPrint('Error al limpiar descargas incompletas: $error\n$stack');
    }
  }

  Future<void> cargarCatalogo() async {
    _estaCargando = true;
    _huboErrorAlCargar = false;
    notifyListeners();

    try {
      final resultado = await _repositorio.obtenerCatalogo();
      _catalogo = resultado.modulos;
      _vieneDeCache = resultado.vieneDeCache;
    } catch (error, stack) {
      debugPrint('Error al cargar el catálogo: $error\n$stack');
      _huboErrorAlCargar = true;
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarDescargados() async {
    try {
      _descargados = await _repositorio.obtenerDescargados();
    } catch (error, stack) {
      debugPrint('Error al cargar las descargas: $error\n$stack');
    }
    notifyListeners();
  }

  Modulo? buscarModulo(String id) {
    for (final modulo in [..._catalogo, ..._descargados]) {
      if (modulo.id == id) {
        return modulo;
      }
    }

    return null;
  }

  EstadoDescarga obtenerEstado(Modulo modulo) {
    if (_estaDescargando(modulo.id)) {
      return EstadoDescarga.descargando;
    }
    // Si falló una actualización el módulo sigue usable; el error se muestra aparte.
    if (_errorPorModulo.containsKey(modulo.id) && !modulo.estaDescargado) {
      return EstadoDescarga.error;
    }

    return modulo.estadoDescarga;
  }

  double? obtenerProgreso(String moduloId) => _progresoPorModulo[moduloId];

  String? obtenerMensajeError(Modulo modulo) {
    final mensajeGuardado = _errorPorModulo[modulo.id];

    if (mensajeGuardado != null) {
      return mensajeGuardado;
    }
    if (modulo.estadoDescarga == EstadoDescarga.error) {
      return _mensajeDescargaInterrumpida;
    }

    return null;
  }

  Future<bool> eliminarDescarga(Modulo modulo) async {
    final fueEliminado = await _intentarEliminarDescarga(modulo);

    await _refrescarModulo(modulo.id);
    await cargarDescargados();

    return fueEliminado;
  }

  Future<bool> descargar(Modulo modulo) async {
    if (_estaDescargando(modulo.id)) {
      return false;
    }

    _errorPorModulo.remove(modulo.id);
    _progresoPorModulo[modulo.id] = 0;
    notifyListeners();

    final fueDescargado = await _intentarDescargar(modulo);

    _progresoPorModulo.remove(modulo.id);
    await _refrescarModulo(modulo.id);
    notifyListeners();

    return fueDescargado;
  }

  Future<List<RecursoLocal>> obtenerRecursos(Modulo modulo) async {
    try {
      return await _repositorio.obtenerRecursosLocales(modulo);
    } on ContenidoIncompletoException {
      _errorPorModulo[modulo.id] = _mensajeFaltanArchivos;
      await _refrescarModulo(modulo.id);
      notifyListeners();
      rethrow;
    }
  }

  bool _estaDescargando(String moduloId) {
    return _progresoPorModulo.containsKey(moduloId);
  }

  Future<bool> _intentarEliminarDescarga(Modulo modulo) async {
    try {
      await _repositorio.eliminarDescarga(modulo);
      _errorPorModulo.remove(modulo.id);
      return true;
    } catch (error, stack) {
      debugPrint('Error al eliminar la descarga de ${modulo.id}: $error\n$stack');
      return false;
    }
  }

  Future<bool> _intentarDescargar(Modulo modulo) async {
    try {
      await _descargaService.descargar(
        modulo,
        onProgreso: (progreso) => _actualizarProgreso(modulo.id, progreso),
      );
      return true;
    } on DescargaException catch (error) {
      _errorPorModulo[modulo.id] = error.mensaje;
      return false;
    } catch (error, stack) {
      debugPrint('Error inesperado al descargar ${modulo.id}: $error\n$stack');
      _errorPorModulo[modulo.id] = _mensajeErrorInesperado;
      return false;
    }
  }

  void _actualizarProgreso(String moduloId, double progreso) {
    final progresoAnterior = _progresoPorModulo[moduloId] ?? 0;

    if (_cambioElPorcentaje(progresoAnterior, progreso)) {
      _progresoPorModulo[moduloId] = progreso;
      notifyListeners();
    }
  }

  bool _cambioElPorcentaje(double anterior, double actual) {
    return (actual * _pasosDeProgreso).floor() !=
        (anterior * _pasosDeProgreso).floor();
  }

  Future<void> _refrescarModulo(String id) async {
    final Modulo? actualizado;

    try {
      actualizado = await _repositorio.obtenerModulo(id);
    } catch (error, stack) {
      debugPrint('Error al leer el módulo $id: $error\n$stack');
      return;
    }

    if (actualizado == null) {
      return;
    }

    _catalogo = [
      for (final modulo in _catalogo) modulo.id == id ? actualizado : modulo,
    ];
  }
}
