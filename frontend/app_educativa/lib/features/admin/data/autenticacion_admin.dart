import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/acceso_admin_exception.dart';
import '../domain/superadministrador.dart';
import 'firebase_admin.dart';

/// Inicio de sesión del superadministrador (HU12). Las pantallas solo
/// conocen esta interfaz; en las pruebas se reemplaza por una falsa.
abstract interface class AutenticacionAdmin {
  /// Devuelve el administrador o lanza [AccesoAdminException].
  Future<Superadministrador> iniciarSesion(String correo, String password);

  Future<void> cerrarSesion();
}

/// Valida con Firebase Authentication (correo y contraseña) y comprueba que
/// el usuario esté en `administradores/{uid}`. Las reglas de Firestore usan
/// esa misma colección para dejarle editar módulos y leer el progreso.
class FirebaseAutenticacionAdmin implements AutenticacionAdmin {
  static const String coleccionAdministradores = 'administradores';
  static const Duration _tiempoMaximo = Duration(seconds: 20);

  final Future<FirebaseAuth> Function() _auth;
  final Future<FirebaseFirestore> Function() _firestore;

  FirebaseAutenticacionAdmin({
    Future<FirebaseAuth> Function()? auth,
    Future<FirebaseFirestore> Function()? firestore,
  })  : _auth = auth ?? FirebaseAdmin.auth,
        _firestore = firestore ?? FirebaseAdmin.firestore;

  @override
  Future<Superadministrador> iniciarSesion(
    String correo,
    String password,
  ) async {
    final auth = await _auth();

    try {
      final credencial = await auth
          .signInWithEmailAndPassword(email: correo, password: password)
          .timeout(_tiempoMaximo);
      final usuario = credencial.user!;

      final registro = await (await _firestore())
          .collection(coleccionAdministradores)
          .doc(usuario.uid)
          .get()
          .timeout(_tiempoMaximo);

      if (!registro.exists) {
        await auth.signOut();
        throw const AccesoAdminException(AccesoAdminException.datosInvalidos);
      }

      return Superadministrador(
        id: usuario.uid,
        usuario: registro.data()?['nombre'] as String? ?? usuario.email ?? '',
      );
    } on FirebaseException catch (error) {
      // Incluye FirebaseAuthException. Un permiso negado al leer
      // administradores/{uid} significa que no es administrador.
      await auth.signOut();
      throw AccesoAdminException(mensajeDeAcceso(error.code), error);
    } on TimeoutException catch (error) {
      await auth.signOut();
      throw AccesoAdminException(AccesoAdminException.sinConexion, error);
    }
  }

  @override
  Future<void> cerrarSesion() async {
    await (await _auth()).signOut();
  }
}

/// Mensaje para el administrador según el código de error de Firebase.
/// No dice si falló el correo o la contraseña, para no dar pistas.
String mensajeDeAcceso(String codigo) {
  return switch (codigo) {
    'network-request-failed' || 'unavailable' => AccesoAdminException.sinConexion,
    'too-many-requests' => AccesoAdminException.demasiadosIntentos,
    _ => AccesoAdminException.datosInvalidos,
  };
}
