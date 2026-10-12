/// Recurso de un módulo descargado, listo para abrirse desde el dispositivo.
class RecursoLocal {
  final String titulo;
  final String tipo;
  final String ruta;

  const RecursoLocal({
    required this.titulo,
    required this.tipo,
    required this.ruta,
  });
}

/// El módulo figura como descargado pero faltan archivos en el dispositivo.
class ContenidoIncompletoException implements Exception {
  final String detalle;

  const ContenidoIncompletoException(this.detalle);

  @override
  String toString() => 'ContenidoIncompletoException: $detalle';
}
