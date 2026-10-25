import '../../../core/network/servidor_exception.dart';
import '../../progreso/domain/progreso_pendiente.dart';

/// Destino del progreso en el servidor (patrón Strategy, igual que con los
/// contenidos): la sincronización no sabe si los datos van a Firestore o a
/// otro servidor.
abstract interface class ProgresoRemoteDataSource {
  /// Envía [pendientes]. Si algo falla lanza una excepción, y entonces los
  /// datos siguen pendientes en el teléfono.
  Future<void> enviar(ProgresoPendiente pendientes);
}

/// Se usa cuando no hay un servidor configurado para el progreso: todo
/// queda guardado en el teléfono como pendiente.
class SinServidorProgresoRemoteDataSource implements ProgresoRemoteDataSource {
  const SinServidorProgresoRemoteDataSource();

  @override
  Future<void> enviar(ProgresoPendiente pendientes) async {
    throw const ServidorException(
      'No hay un servidor configurado para el progreso.',
    );
  }
}

/// Un documento por escribir en el servidor.
typedef DocumentoProgreso = ({String ruta, Map<String, Object?> datos});

/// Convierte las filas pendientes en documentos con una ruta fija por
/// registro. Enviar dos veces lo mismo solo vuelve a escribir el mismo
/// documento, así que reintentar es seguro.
///
/// ```
/// estudiantes/{perfil}
/// estudiantes/{perfil}/modulos/{modulo}
/// estudiantes/{perfil}/lecturas/{modulo}__{documento}
/// estudiantes/{perfil}/actividades/{modulo}__{actividad}
/// ```
///
/// [uid] es el usuario de Firebase (sesión anónima) dueño de los datos: las
/// reglas de Firestore solo dejan que ese usuario los modifique (HU11).
List<DocumentoProgreso> documentosDeProgreso(
  ProgresoPendiente pendientes, {
  String? uid,
}) {
  final estudiante = 'estudiantes/${idSeguro(pendientes.perfilId)}';

  Map<String, Object?> datosDe(Map<String, Object?> fila) {
    return {
      for (final MapEntry(:key, :value) in fila.entries)
        if (key != 'id' && key != 'sincronizado') key: value,
      if (uid != null) 'uid': uid,
    };
  }

  return [
    (
      ruta: estudiante,
      datos: {
        'perfil_id': pendientes.perfilId,
        if (pendientes.nombreEstudiante != null)
          'nombre': pendientes.nombreEstudiante,
        if (uid != null) 'uid': uid,
      },
    ),
    for (final fila in pendientes.modulos)
      (
        ruta: '$estudiante/modulos/${idSeguro(fila['modulo_id'])}',
        datos: datosDe(fila),
      ),
    for (final fila in pendientes.lecturas)
      (
        ruta: '$estudiante/lecturas/'
            '${idSeguro(fila['modulo_id'])}__${idSeguro(fila['recurso'])}',
        datos: datosDe(fila),
      ),
    for (final fila in pendientes.actividades)
      (
        ruta: '$estudiante/actividades/'
            '${idSeguro(fila['modulo_id'])}__${idSeguro(fila['actividad_id'])}',
        datos: datosDe(fila),
      ),
  ];
}

/// Los identificadores de Firestore no pueden tener `/`.
String idSeguro(Object? valor) => '$valor'.replaceAll('/', '_');
