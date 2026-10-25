class ApiConfig {
  ApiConfig._();

  // Se cambia con --dart-define=API_BASE_URL=... (sin "/" al final).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://raw.githubusercontent.com/DannaLagos/'
        'app-educativa-offline/main/backend/contenidos',
  );

  static const Duration tiempoEspera = Duration(seconds: 15);
}
