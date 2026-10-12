import 'package:flutter/foundation.dart';

import '../../data/descarga_service.dart';
import '../../data/modulo_repository.dart';
import '../../domain/estado_descarga.dart';
import '../../domain/modulo.dart';
import '../../domain/recurso_local.dart';

/// Estado compartido de los módulos para la lista, el detalle y
/// "Mis descargas". La interfaz solo habla con este controlador.
class ModulosController extends ChangeNotifier {
  final ModuloRepository _repositorio;
  final DescargaService _descargaService;

  ModulosController({
    required ModuloRepository repositorio,
    required DescargaService descargaService,
  })  : _repositorio = repositorio,
        _descargaService = descargaService;

  List<Modulo> _catalogo = const [];
  List<Modulo> _descargados = const [];
  bool _cargando = false;
  bool _desdeCache = false;
  bool _errorCarga = false;

  /// Progreso (0 a 1) de las descargas en curso, por id de módulo.
  final Map<String, double> _progreso = {};

  /// Último mensaje de error de descarga, por id de módulo.
  final Map<String, String> _errores = {};

  List<Modulo> get catalogo => _catalogo;
  List<Modulo> get descargados => _descargados;
  bool get cargando => _cargando;
  bool get desdeCache => _desdeCache;
  bool get errorCarga => _errorCarga;

  /// Limpia descargas que quedaron a medias. Se llama al abrir la app.
  Future<void> inicializar() async {
    try {
      await _descargaService.limpiarIncompletas();
    } catch (error, stack) {
      debugPrint('Error al limpiar descargas incompletas: $error\n$stack');
    }
  }

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
    for (final modulo in [..._catalogo, ..._descargados]) {
      if (modulo.id == id) {
        return modulo;
      }
    }

    return null;
  }

  EstadoDescarga estadoDe(Modulo modulo) {
    if (_progreso.containsKey(modulo.id)) {
      return EstadoDescarga.descargando;
    }
    if (_errores.containsKey(modulo.id)) {
      return EstadoDescarga.error;
    }

    return modulo.estadoDescarga;
  }

  double? progresoDe(String moduloId) => _progreso[moduloId];

  /// Mensaje del último error. Si la app se reinició después del error, el
  /// estado viene de la base de datos y se usa un mensaje general.
  String? errorDe(Modulo modulo) {
    return _errores[modulo.id] ??
        (modulo.estadoDescarga == EstadoDescarga.error
            ? 'La descarga anterior no terminó. Vuelve a intentarlo.'
            : null);
  }

  Future<void> cargarDescargados() async {
    try {
      _descargados = await _repositorio.obtenerDescargados();
    } catch (error, stack) {
      debugPrint('Error al cargar las descargas: $error\n$stack');
    }
    notifyListeners();
  }

  /// Elimina los archivos del módulo. Devuelve false si no se pudo.
  Future<bool> eliminarDescarga(Modulo modulo) async {
    var exito = false;

    try {
      await _repositorio.eliminarDescarga(modulo);
      _errores.remove(modulo.id);
      exito = true;
    } catch (error, stack) {
      debugPrint('Error al eliminar la descarga: $error\n$stack');
    }

    await _refrescarModulo(modulo.id);
    // Se relee desde la base de datos para reflejar el estado real, haya
    // funcionado o no.
    await cargarDescargados();

    return exito;
  }

  /// Devuelve true si el módulo quedó descargado.
  Future<bool> descargar(Modulo modulo) async {
    if (_progreso.containsKey(modulo.id)) {
      return false;
    }

    _errores.remove(modulo.id);
    _progreso[modulo.id] = 0;
    notifyListeners();

    var exito = false;

    try {
      await _descargaService.descargar(
        modulo,
        onProgreso: (progreso) => _actualizarProgreso(modulo.id, progreso),
      );
      exito = true;
    } on DescargaException catch (error) {
      _errores[modulo.id] = error.mensaje;
    } catch (error, stack) {
      debugPrint('Error inesperado al descargar: $error\n$stack');
      _errores[modulo.id] = 'No se pudo descargar el módulo. '
          'Vuelve a intentarlo.';
    }

    _progreso.remove(modulo.id);
    await _refrescarModulo(modulo.id);
    notifyListeners();

    return exito;
  }

  /// Recursos del módulo descargado, leídos solo del dispositivo. Si faltan
  /// archivos, el módulo queda en "error" para volver a descargarlo.
  Future<List<RecursoLocal>> recursosDe(Modulo modulo) async {
    try {
      return await _repositorio.obtenerRecursosLocales(modulo);
    } on ContenidoIncompletoException {
      _errores[modulo.id] =
          'Faltan archivos de este módulo. Descárgalo de nuevo.';
      await _refrescarModulo(modulo.id);
      notifyListeners();
      rethrow;
    }
  }

  void _actualizarProgreso(String moduloId, double progreso) {
    final anterior = _progreso[moduloId] ?? 0;

    // Notifica solo cuando cambia al menos un punto porcentual, para no
    // reconstruir la interfaz con cada bloque de bytes.
    if ((progreso * 100).floor() != (anterior * 100).floor()) {
      _progreso[moduloId] = progreso;
      notifyListeners();
    }
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
