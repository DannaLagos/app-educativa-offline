class ContenidoIncompletoException implements Exception {
  final String detalle;

  const ContenidoIncompletoException(this.detalle);

  @override
  String toString() => 'ContenidoIncompletoException: $detalle';
}
