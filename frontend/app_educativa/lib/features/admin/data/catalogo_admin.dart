import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/servidor_exception.dart';
import '../../modulos/data/firebase_modulo_remote_datasource.dart';
import '../../modulos/domain/modulo.dart';
import 'firebase_admin.dart';

/// Gestión de los módulos por el superadministrador (HU13).
abstract interface class CatalogoAdmin {
  /// Todos los módulos registrados, habilitados o no (criterio 1).
  Future<List<Modulo>> obtenerModulos();

  /// Lanza [ModuloYaExisteException] si el id ya está en uso.
  Future<void> registrar(Modulo modulo);

  Future<void> actualizar(Modulo modulo);

  /// Criterio 3: un módulo deshabilitado deja de verse en la app del
  /// estudiante la próxima vez que se actualice su catálogo.
  Future<void> cambiarHabilitado(String moduloId, bool habilitado);
}

class ModuloYaExisteException implements Exception {
  final String moduloId;

  const ModuloYaExisteException(this.moduloId);

  @override
  String toString() => 'ModuloYaExisteException: $moduloId';
}

/// Guarda los módulos en la colección `catalogo` de Firestore, un documento
/// por módulo con los mismos campos de catalogo.json. Las reglas solo dejan
/// escribir a los usuarios de `administradores`.
class FirestoreCatalogoAdmin implements CatalogoAdmin {
  static const Duration _tiempoMaximo = Duration(seconds: 20);

  final Future<FirebaseFirestore> Function() _firestore;

  /// Lee catalogo.json de Storage, para llenar la colección la primera vez.
  final Future<List<Modulo>> Function() _leerCatalogoInicial;

  FirestoreCatalogoAdmin({
    Future<FirebaseFirestore> Function()? firestore,
    Future<List<Modulo>> Function()? leerCatalogoInicial,
  })  : _firestore = firestore ?? FirebaseAdmin.firestore,
        _leerCatalogoInicial = leerCatalogoInicial ?? _catalogoDeStorage;

  static Future<List<Modulo>> _catalogoDeStorage() async {
    return FirebaseModuloRemoteDataSource(
      storage: await FirebaseAdmin.storage(),
    ).obtenerCatalogo();
  }

  Future<CollectionReference<Map<String, dynamic>>> _coleccion() async {
    return (await _firestore()).collection(ApiConfig.coleccionCatalogo);
  }

  @override
  Future<List<Modulo>> obtenerModulos() {
    return _ejecutar('No fue posible leer los módulos.', () async {
      final consulta = await (await _coleccion()).get().timeout(_tiempoMaximo);

      final modulos = consulta.docs.isEmpty
          ? await _importarCatalogoInicial()
          : [
              for (final documento in consulta.docs)
                Modulo.desdeCatalogo({...documento.data(), 'id': documento.id}),
            ];

      return modulos..sort(_porAreaGradoYNombre);
    });
  }

  /// La primera vez la colección está vacía: se copian los módulos de
  /// catalogo.json para que el administrador los gestione desde aquí.
  Future<List<Modulo>> _importarCatalogoInicial() async {
    final modulos = await _leerCatalogoInicial();
    final coleccion = await _coleccion();
    final lote = coleccion.firestore.batch();

    for (final modulo in modulos) {
      lote.set(coleccion.doc(modulo.id), _datosDe(modulo));
    }

    await lote.commit().timeout(_tiempoMaximo);

    return modulos;
  }

  @override
  Future<void> registrar(Modulo modulo) {
    return _ejecutar('No fue posible registrar el módulo.', () async {
      final coleccion = await _coleccion();
      final documento = coleccion.doc(modulo.id);

      await coleccion.firestore.runTransaction((transaccion) async {
        if ((await transaccion.get(documento)).exists) {
          throw ModuloYaExisteException(modulo.id);
        }

        transaccion.set(documento, _datosDe(modulo));
      }).timeout(_tiempoMaximo);
    });
  }

  @override
  Future<void> actualizar(Modulo modulo) {
    return _ejecutar('No fue posible guardar los cambios.', () async {
      await (await _coleccion())
          .doc(modulo.id)
          .update(_datosDe(modulo))
          .timeout(_tiempoMaximo);
    });
  }

  @override
  Future<void> cambiarHabilitado(String moduloId, bool habilitado) {
    return _ejecutar('No fue posible cambiar el estado del módulo.', () async {
      await (await _coleccion()).doc(moduloId).update({
        'habilitado': habilitado,
        'actualizado_en': FieldValue.serverTimestamp(),
      }).timeout(_tiempoMaximo);
    });
  }

  Map<String, dynamic> _datosDe(Modulo modulo) {
    return {
      ...modulo.toCatalogo()..remove('id'),
      'actualizado_en': FieldValue.serverTimestamp(),
    };
  }

  /// Convierte los errores de Firebase y las esperas largas en
  /// [ServidorException], para mostrar un solo tipo de error en pantalla.
  Future<T> _ejecutar<T>(String mensaje, Future<T> Function() accion) async {
    try {
      return await accion();
    } on FirebaseException catch (error) {
      throw ServidorException(mensaje, error);
    } on TimeoutException catch (error) {
      throw ServidorException('$mensaje Revisa la conexión a internet.', error);
    }
  }
}

int _porAreaGradoYNombre(Modulo a, Modulo b) {
  return switch (a.area.compareTo(b.area)) {
    0 => switch (a.grado.compareTo(b.grado)) {
        0 => a.nombre.compareTo(b.nombre),
        final orden => orden,
      },
    final orden => orden,
  };
}
