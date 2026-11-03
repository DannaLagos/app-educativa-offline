/// Resultado de un intento de sincronización (HU10).
sealed class ResultadoSincronizacion {
  const ResultadoSincronizacion();
}

/// No había nada por enviar.
class SinPendientes extends ResultadoSincronizacion {
  const SinPendientes();
}

/// El servidor recibió los datos.
class Enviado extends ResultadoSincronizacion {
  final int registros;

  const Enviado(this.registros);
}

/// No hay red: los datos se quedan guardados para enviarlos después.
class SinConexion extends ResultadoSincronizacion {
  final int pendientes;

  const SinConexion(this.pendientes);
}

/// El envío falló. Los datos siguen pendientes en el teléfono (criterio 3).
class FalloSincronizacion extends ResultadoSincronizacion {
  final Object error;
  final int pendientes;

  const FalloSincronizacion(this.error, this.pendientes);
}

/// Lo que ve el estudiante sobre su progreso.
enum EstadoSincronizacion {
  /// Todo enviado.
  alDia,

  /// Hay avances guardados que todavía no se envían.
  pendiente,

  /// Enviando en este momento.
  sincronizando,

  /// El último envío falló; se volverá a intentar.
  error,
}
