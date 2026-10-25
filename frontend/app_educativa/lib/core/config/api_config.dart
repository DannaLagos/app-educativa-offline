class ApiConfig {
  ApiConfig._();

  /// De dónde se descargan los contenidos:
  /// - `firebase` (por defecto): Firebase Storage.
  /// - `http`: un servidor HTTP en [baseUrl] (por ejemplo, uno local).
  ///
  /// Se cambia con `--dart-define=FUENTE_CONTENIDOS=http`.
  static const String fuenteContenidos = String.fromEnvironment(
    'FUENTE_CONTENIDOS',
    defaultValue: 'firebase',
  );

  static bool get usaFirebase => fuenteContenidos != 'http';

  /// Carpeta de Firebase Storage que contiene catalogo.json y modulos/.
  static const String carpetaFirebase = 'contenidos';

  /// Solo para `FUENTE_CONTENIDOS=http`. Se cambia con
  /// `--dart-define=API_BASE_URL=...` (sin "/" al final).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const Duration tiempoEspera = Duration(seconds: 15);

  /// Cuánto reintenta Firebase Storage antes de dar una descarga por
  /// fallida (por defecto son 10 minutos, demasiado para un niño esperando).
  static const Duration reintentoFirebase = Duration(seconds: 30);
}
