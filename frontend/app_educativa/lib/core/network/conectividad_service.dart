import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Revisa si hay internet de verdad (HU10).
///
/// Tener wifi o datos activos no basta: el teléfono puede estar conectado a
/// un router sin internet (o, en el emulador, a la red del PC). Por eso,
/// además de mirar la red, se intenta llegar al servidor de Firebase.
class ConectividadService {
  /// Servidor que se usa para comprobar que hay internet.
  static const String _hostPrueba = 'firestore.googleapis.com';

  final Connectivity _connectivity;
  final Future<bool> Function() _hayInternet;
  final Duration _intervalo;

  ConectividadService({
    Connectivity? connectivity,
    Future<bool> Function()? hayInternet,
    Duration intervalo = const Duration(seconds: 10),
  })  : _connectivity = connectivity ?? Connectivity(),
        _hayInternet = hayInternet ?? _llegaAlServidor,
        _intervalo = intervalo;

  Future<bool> hayConexion() async {
    try {
      final resultados = await _connectivity.checkConnectivity();

      if (!_hayRed(resultados)) {
        return false;
      }
    } catch (_) {
      // Si no se puede leer la red, decide la prueba real.
    }

    return _hayInternet();
  }

  /// Avisa cada vez que se gana o se pierde el internet. Se revisa cuando
  /// cambia la red y, además, cada [_intervalo], porque perder el internet
  /// sin perder el wifi no genera ningún aviso del teléfono. Solo emite
  /// cuando el valor cambia.
  Stream<bool> get cambios {
    late StreamController<bool> controlador;
    StreamSubscription<List<ConnectivityResult>>? suscripcion;
    Timer? temporizador;
    var revisando = false;

    Future<void> revisar() async {
      if (revisando) {
        return;
      }
      revisando = true;
      final hay = await hayConexion();
      revisando = false;

      if (!controlador.isClosed) {
        controlador.add(hay);
      }
    }

    controlador = StreamController<bool>(
      onListen: () {
        suscripcion = _connectivity.onConnectivityChanged.listen(
          (_) => revisar(),
          onError: (Object _) => revisar(),
        );
        temporizador = Timer.periodic(_intervalo, (_) => revisar());
      },
      onCancel: () async {
        temporizador?.cancel();
        await suscripcion?.cancel();
      },
    );

    return controlador.stream.distinct();
  }

  static bool _hayRed(List<ConnectivityResult> resultados) {
    return resultados.any(
      (resultado) => resultado != ConnectivityResult.none,
    );
  }

  /// Intenta abrir una conexión con Firebase. Si en 4 segundos no se puede,
  /// se considera que no hay internet.
  static Future<bool> _llegaAlServidor() async {
    try {
      final socket = await Socket.connect(
        _hostPrueba,
        443,
        timeout: const Duration(seconds: 4),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
