enum MotivoFalloDescarga {
  sinConexion(
    'No hay internet. Conéctate a una red y vuelve a intentarlo.',
  ),
  conexionInterrumpida(
    'Se perdió la conexión durante la descarga. Vuelve a intentarlo.',
  ),
  archivoDanado(
    'Un archivo llegó dañado. Vuelve a intentarlo.',
  ),
  sinEspacio(
    'No se pudo guardar el módulo. Revisa que haya espacio libre.',
  );

  final String mensaje;

  const MotivoFalloDescarga(this.mensaje);
}

class DescargaException implements Exception {
  final MotivoFalloDescarga motivo;
  final Object? causa;

  const DescargaException(this.motivo, [this.causa]);

  String get mensaje => motivo.mensaje;

  @override
  String toString() => 'DescargaException: ${motivo.name} ($causa)';
}
