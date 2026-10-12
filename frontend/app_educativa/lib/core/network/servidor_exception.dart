/// Error al hablar con el servidor de contenidos: sin red, tiempo agotado,
/// respuesta inválida, etc.
class ServidorException implements Exception {
  final String mensaje;
  final Object? causa;

  const ServidorException(this.mensaje, [this.causa]);

  @override
  String toString() => 'ServidorException: $mensaje ($causa)';
}
