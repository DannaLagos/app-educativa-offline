import '../../../core/network/servidor_exception.dart';
import '../domain/archivo_por_descargar.dart';
import '../domain/manifest_modulo.dart';
import '../domain/modulo.dart';

/// Origen remoto de los contenidos (patrón Repository + Data Source).
///
/// El resto de la app solo conoce esta interfaz, así que el servidor se puede
/// cambiar sin tocar el repositorio, la descarga ni las pantallas:
///
/// - [FirebaseModuloRemoteDataSource]: Firebase Storage (el que usa la app).
/// - [HttpModuloRemoteDataSource]: cualquier servidor HTTP con la misma
///   estructura de carpetas (útil para probar con un servidor local).
abstract class ModuloRemoteDataSource {
  /// Lee `catalogo.json`.
  Future<List<Modulo>> obtenerCatalogo();

  /// Lee `modulos/<moduloId>/manifest.json`.
  Future<ManifestModulo> obtenerManifest(String moduloId);

  /// Descarga `modulos/<moduloId>/<nombre>` en [ArchivoPorDescargar.rutaDestino].
  /// [onRecibido] informa los bytes recibidos de ese archivo.
  Future<void> descargarArchivo(
    ArchivoPorDescargar archivo, {
    void Function(int bytesRecibidos)? onRecibido,
  });
}

/// Convierte el JSON de `catalogo.json` en módulos.
List<Modulo> interpretarCatalogo(Map<String, dynamic> json) {
  return interpretarRespuesta(
    () => (json['modulos'] as List)
        .map(
          (entrada) => Modulo.desdeCatalogo(
            entrada as Map<String, dynamic>,
          ),
        )
        .toList(),
    mensajeError: 'El catálogo no tiene el formato esperado.',
  );
}

/// Convierte el JSON de un `manifest.json`.
ManifestModulo interpretarManifest(String moduloId, Map<String, dynamic> json) {
  return interpretarRespuesta(
    () => ManifestModulo.fromJson(json),
    mensajeError: 'El manifest del módulo $moduloId no es válido.',
  );
}

/// Ejecuta [interpretar] y convierte los errores de formato en
/// [ServidorException], para que el repositorio los trate como un fallo del
/// servidor (y use la copia local).
T interpretarRespuesta<T>(
  T Function() interpretar, {
  required String mensajeError,
}) {
  try {
    return interpretar();
  } on FormatException catch (error) {
    throw ServidorException(mensajeError, error);
  } on TypeError catch (error) {
    throw ServidorException(mensajeError, error);
  }
}
