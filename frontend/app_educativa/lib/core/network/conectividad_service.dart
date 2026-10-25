import 'package:connectivity_plus/connectivity_plus.dart';

// Una red activa no garantiza internet: quien llame al servidor maneja sus errores.
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
