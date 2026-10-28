import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/progreso_repository.dart';
import '../domain/progreso_modulo.dart';
import '../domain/resultado_actividad.dart';

/// Estado del progreso para las pantallas (patrón Observer con
/// ChangeNotifier). Si guardar falla, se registra el error pero nunca se
/// interrumpe al estudiante.
class ProgresoController extends ChangeNotifier {
  final ProgresoRepository _repositorio;
  final Map<String, ProgresoModulo> _porModulo = {};
  String? _ultimoModuloId;

  ProgresoController({required ProgresoRepository repositorio})
      : _repositorio = repositorio;

  /// Módulo en el que el estudiante avanzó por última vez, para ofrecerle
  /// continuar donde iba (HU08).
  String? get ultimoModuloId => _ultimoModuloId;

  /// Se llama al abrir la app. Solo usa la base local: funciona sin internet.
  Future<void> cargarUltimoModulo() async {
    try {
      final id = await _repositorio.obtenerUltimoModulo();
      _ultimoModuloId = id;

      if (id != null) {
        await cargarProgreso(id);
        return;
      }
    } catch (error, stack) {
      debugPrint('Error al leer el último módulo: $error\n$stack');
    }
    notifyListeners();
  }

  /// Progreso ya cargado del módulo (vacío si aún no se ha cargado).
  ProgresoModulo progresoDe(String moduloId) {
    return _porModulo[moduloId] ?? ProgresoModulo.vacio(moduloId);
  }

  Future<ProgresoModulo> cargarProgreso(String moduloId) async {
    try {
      final progreso = await _repositorio.obtenerProgresoModulo(moduloId);
      _porModulo[moduloId] = progreso;
      notifyListeners();
    } catch (error, stack) {
      debugPrint('Error al leer el progreso de $moduloId: $error\n$stack');
    }

    return progresoDe(moduloId);
  }

  /// Vuelve a leer de SQLite los módulos ya cargados. Se usa después de
  /// sincronizar, para que las pantallas muestren qué quedó en la nube (HU11).
  Future<void> recargarCargados() async {
    for (final moduloId in List.of(_porModulo.keys)) {
      await cargarProgreso(moduloId);
    }
  }

  /// Página desde la que se debe abrir [recurso], o null si nunca se abrió.
  Future<int?> paginaParaContinuar(String moduloId, String recurso) async {
    final lectura = (await cargarProgreso(moduloId)).lecturaDe(recurso);

    if (lectura == null) {
      return null;
    }

    return min(max(lectura.ultimaPagina, 1), lectura.totalPaginas);
  }

  /// Devuelve false si no se pudo guardar.
  Future<bool> guardarPagina({
    required String moduloId,
    required String recurso,
    required int pagina,
    required int totalPaginas,
  }) {
    return _guardar(
      moduloId,
      () => _repositorio.guardarPaginaLeida(
        moduloId: moduloId,
        recurso: recurso,
        pagina: pagina,
        totalPaginas: totalPaginas,
      ),
    );
  }

  /// Lo usan las actividades y juegos (HU07). Devuelve false si no se pudo
  /// guardar.
  Future<bool> registrarResultado(ResultadoActividad resultado) {
    return _guardar(
      resultado.moduloId,
      () => _repositorio.registrarResultadoActividad(resultado),
    );
  }

  Future<bool> _guardar(String moduloId, Future<void> Function() guardar) async {
    try {
      await guardar();
    } catch (error, stack) {
      debugPrint('Error al guardar el progreso de $moduloId: $error\n$stack');
      return false;
    }

    _ultimoModuloId = moduloId;
    await cargarProgreso(moduloId);
    return true;
  }
}
