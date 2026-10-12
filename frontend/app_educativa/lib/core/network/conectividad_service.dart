import 'package:connectivity_plus/connectivity_plus.dart';

/// Indica si el dispositivo tiene alguna red activa. No garantiza que haya
/// internet: quien llame al servidor debe manejar también los errores de red.
class ConectividadService {
  final Connectivity _connectivity;

  ConectividadService({
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  Future<bool> hayConexion() async {
    final resultados = await _connectivity.checkConnectivity();

    return resultados.any(
      (resultado) => resultado != ConnectivityResult.none,
    );
  }
}
