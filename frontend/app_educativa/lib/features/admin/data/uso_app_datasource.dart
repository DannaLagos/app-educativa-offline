import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/servidor_exception.dart';
import '../domain/resumen_uso.dart';
import 'firebase_admin.dart';

/// Lee los datos sincronizados de todos los estudiantes (HU14).
abstract interface class UsoAppDataSource {
  Future<DatosUso> obtenerDatos();
}

/// Lee `estudiantes/{perfil}` y sus subcolecciones con consultas de grupo
/// (`collectionGroup`): cuatro lecturas en total, sin importar cuántos
/// estudiantes haya. Las reglas solo dejan leer a los administradores.
class FirestoreUsoAppDataSource implements UsoAppDataSource {
  static const Duration _tiempoMaximo = Duration(seconds: 30);

  final Future<FirebaseFirestore> Function() _firestore;

  FirestoreUsoAppDataSource({
    Future<FirebaseFirestore> Function()? firestore,
  }) : _firestore = firestore ?? FirebaseAdmin.firestore;

  @override
  Future<DatosUso> obtenerDatos() async {
    try {
      final firestore = await _firestore();

      final consultas = await Future.wait([
        firestore.collection('estudiantes').get(),
        firestore.collectionGroup('modulos').get(),
        firestore.collectionGroup('lecturas').get(),
        firestore.collectionGroup('actividades').get(),
        firestore.collection(ApiConfig.coleccionCatalogo).get(),
      ]).timeout(_tiempoMaximo);

      return DatosUso(
        estudiantes: _filas(consultas[0]),
        modulos: _filas(consultas[1]),
        lecturas: _filas(consultas[2]),
        actividades: _filas(consultas[3]),
        nombresModulos: {
          for (final documento in consultas[4].docs)
            documento.id: documento.data()['nombre'] as String? ?? documento.id,
        },
      );
    } on FirebaseException catch (error) {
      throw ServidorException(
        'No fue posible consultar la información de uso.',
        error,
      );
    } on TimeoutException catch (error) {
      throw ServidorException(
        'La consulta tardó demasiado. Revisa la conexión a internet.',
        error,
      );
    }
  }

  /// Los `Timestamp` de Firestore pasan a [DateTime].
  List<Map<String, Object?>> _filas(QuerySnapshot<Map<String, dynamic>> consulta) {
    return [
      for (final documento in consulta.docs)
        {
          for (final MapEntry(:key, :value) in documento.data().entries)
            key: value is Timestamp ? value.toDate() : value,
        },
    ];
  }
}
