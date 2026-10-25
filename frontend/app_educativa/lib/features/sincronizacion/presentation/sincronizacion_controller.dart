import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/conectividad_service.dart';
import '../data/sincronizacion_service.dart';
import '../domain/resultado_sincronizacion.dart';

/// Estado de la conexión y de la sincronización para las pantallas (HU10,
/// patrón Observer con ChangeNotifier).
///
/// - Escucha los cambios de red: al perder la conexión lo avisa (criterio 1)
///   y al recuperarla vuelve a intentar el envío (criterio 4).
/// - Escucha el progreso: cuando el estudiante avanza, intenta enviarlo.
/// - Si un envío falla, lo reintenta más tarde; los datos nunca se borran
///   (criterio 3).
class SincronizacionController extends ChangeNotifier {
  final SincronizacionService _servicio;
  final ConectividadService _conectividad;
  final Duration _esperaTrasCambio;
  final Duration _esperaReintento;
  final DateTime Function() _ahora;

  StreamSubscription<bool>? _suscripcion;
  Timer? _temporizadorCambio;
  Timer? _temporizadorReintento;

  bool _hayConexion = true;
  int _pendientes = 0;
  bool _sincronizando = false;
  bool _ultimoIntentoFallo = false;
  DateTime? _ultimaSincronizacion;
  bool _cerrado = false;

  SincronizacionController({
    required SincronizacionService servicio,
    required ConectividadService conectividad,
    Duration esperaTrasCambio = const Duration(seconds: 3),
    Duration esperaReintento = const Duration(minutes: 1),
    DateTime Function()? ahora,
  })  : _servicio = servicio,
        _conectividad = conectividad,
        _esperaTrasCambio = esperaTrasCambio,
        _esperaReintento = esperaReintento,
        _ahora = ahora ?? DateTime.now;

  bool get hayConexion => _hayConexion;

  /// Avances guardados en el teléfono que faltan por enviar.
  int get pendientes => _pendientes;

  DateTime? get ultimaSincronizacion => _ultimaSincronizacion;

  EstadoSincronizacion get estado {
    if (_sincronizando) {
      return EstadoSincronizacion.sincronizando;
    }
    if (_pendientes == 0) {
      return EstadoSincronizacion.alDia;
    }
    if (_ultimoIntentoFallo) {
      return EstadoSincronizacion.error;
    }
    return EstadoSincronizacion.pendiente;
  }

  /// Se llama una vez al abrir la app.
  Future<void> iniciar() async {
    _suscripcion ??= _conectividad.cambios.listen(
      _alCambiarConexion,
      onError: (Object error) => debugPrint('Error de conectividad: $error'),
    );

    try {
      _hayConexion = await _conectividad.hayConexion();
    } catch (error) {
      debugPrint('No se pudo revisar la conexión: $error');
    }

    try {
      _ultimaSincronizacion = await _servicio.ultimaSincronizacion();
    } catch (error) {
      debugPrint('No se pudo leer la última sincronización: $error');
    }

    await _actualizarPendientes();
    _notificar();

    if (_hayConexion && _pendientes > 0) {
      await sincronizar();
    }
  }

  void _alCambiarConexion(bool hayConexion) {
    final volvio = hayConexion && !_hayConexion;
    _hayConexion = hayConexion;

    if (!hayConexion) {
      _temporizadorReintento?.cancel();
    }
    _notificar();

    // Criterio 4: al volver la conexión se reintenta lo pendiente.
    if (volvio) {
      sincronizar();
    }
  }

  /// Se conecta al ProgresoController (Observer): cada avance guardado se
  /// cuenta como pendiente y se intenta enviar al poco tiempo. La espera
  /// junta varios avances seguidos en un solo envío.
  void alCambiarProgreso() {
    if (_cerrado) {
      return;
    }

    _temporizadorCambio?.cancel();
    _temporizadorCambio = Timer(_esperaTrasCambio, () async {
      await _actualizarPendientes();
      _notificar();

      if (_hayConexion && _pendientes > 0) {
        await sincronizar();
      }
    });
  }

  /// Envía lo pendiente. También lo usa el botón "Intentar de nuevo".
  Future<ResultadoSincronizacion?> sincronizar() async {
    if (_sincronizando || _cerrado) {
      return null;
    }

    _sincronizando = true;
    _temporizadorReintento?.cancel();
    _notificar();

    ResultadoSincronizacion resultado;
    try {
      resultado = await _servicio.sincronizar();
    } catch (error, stack) {
      debugPrint('Error al sincronizar: $error\n$stack');
      resultado = FalloSincronizacion(error, _pendientes);
    }

    _sincronizando = false;

    switch (resultado) {
      case Enviado():
        _ultimoIntentoFallo = false;
        _ultimaSincronizacion = _ahora();
      case SinPendientes():
        _ultimoIntentoFallo = false;
      case SinConexion():
        _hayConexion = false;
      case FalloSincronizacion():
        _ultimoIntentoFallo = true;
        _programarReintento();
    }

    await _actualizarPendientes();
    _notificar();

    return resultado;
  }

  void _programarReintento() {
    if (!_hayConexion || _cerrado) {
      return;
    }

    _temporizadorReintento?.cancel();
    _temporizadorReintento = Timer(_esperaReintento, sincronizar);
  }

  Future<void> _actualizarPendientes() async {
    try {
      _pendientes = await _servicio.contarPendientes();
    } catch (error) {
      debugPrint('No se pudieron contar los pendientes: $error');
    }
  }

  void _notificar() {
    if (!_cerrado) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cerrado = true;
    _suscripcion?.cancel();
    _temporizadorCambio?.cancel();
    _temporizadorReintento?.cancel();
    super.dispose();
  }
}
