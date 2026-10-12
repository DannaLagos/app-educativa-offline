enum EstadoDescarga {
  noDescargado('no_descargado'),
  descargando('descargando'),
  descargado('descargado'),
  error('error');

  final String valor;

  const EstadoDescarga(this.valor);

  static EstadoDescarga desdeValor(String? valor) {
    for (final estado in values) {
      if (estado.valor == valor) {
        return estado;
      }
    }

    return EstadoDescarga.noDescargado;
  }
}
