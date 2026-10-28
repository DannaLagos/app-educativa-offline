import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/network/servidor_exception.dart';
import '../../progreso/domain/progreso_pendiente.dart';
import 'progreso_remote_datasource.dart';

/// Devuelve el identificador (uid) del usuario de Firebase con el que se
/// envía el progreso. En la app es una sesión anónima (ver `main.dart`).
typedef ObtenerUsuario = Future<String> Function();

/// Envía el progreso a Cloud Firestore (proyecto
/// `aplicacioneducativaoffline`).
///
/// - Cada registro va siempre al mismo documento y se escribe con
///   `merge`, así que sincronizar otra vez actualiza en lugar de duplicar
///   (HU11, criterio 3).
/// - Todo el lote se confirma junto: si falla, el teléfono no marca nada
///   como enviado (HU11, criterio 4).
/// - La caché sin conexión de Firestore se apaga en `main.dart`: la cola de
///   pendientes es SQLite, y así un envío sin internet falla de verdad en
///   lugar de quedar escondido dentro de Firestore.
class FirestoreProgresoRemoteDataSource implements ProgresoRemoteDataSource {
  /// Firestore acepta hasta 500 escrituras por lote.
  static const int _maximoPorLote = 450;

  final FirebaseFirestore _firestore;
  final ObtenerUsuario _obtenerUsuario;
  final Duration _tiempoMaximo;

  FirestoreProgresoRemoteDataSource({
    required FirebaseFirestore firestore,
    required ObtenerUsuario obtenerUsuario,
    Duration tiempoMaximo = const Duration(seconds: 20),
  })  : _firestore = firestore,
        _obtenerUsuario = obtenerUsuario,
        _tiempoMaximo = tiempoMaximo;

  @override
  Future<void> enviar(ProgresoPendiente pendientes) async {
    try {
      final uid = await _obtenerUsuario().timeout(_tiempoMaximo);
      final documentos = documentosDeProgreso(pendientes, uid: uid);

      for (var inicio = 0;
          inicio < documentos.length;
          inicio += _maximoPorLote) {
        final lote = _firestore.batch();

        for (final documento in documentos.skip(inicio).take(_maximoPorLote)) {
          lote.set(
            _firestore.doc(documento.ruta),
            {
              ...documento.datos,
              'sincronizado_en': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }

        await lote.commit().timeout(_tiempoMaximo);
      }
    } on TimeoutException catch (error) {
      throw ServidorException('El servidor tardó demasiado.', error);
    } on FirebaseException catch (error) {
      // También cubre los errores de inicio de sesión (FirebaseAuthException).
      throw ServidorException('Firebase rechazó el envío.', error);
    }
  }
}
