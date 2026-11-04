import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../firebase_options.dart';

/// App de Firebase aparte para el superadministrador (HU12).
///
/// El estudiante usa una sesión anónima en la app principal y su uid queda
/// escrito en cada progreso enviado. Si el administrador iniciara sesión en
/// esa misma app, al cerrar sesión el teléfono recibiría otro uid anónimo y
/// las reglas ya no dejarían actualizar el progreso del niño. Con una app
/// separada, las dos sesiones no se tocan.
class FirebaseAdmin {
  FirebaseAdmin._();

  static const String _nombreApp = 'superadministrador';

  static Future<FirebaseApp>? _app;

  static Future<FirebaseApp> app() {
    return _app ??= _crearApp().catchError((Object error) {
      _app = null;
      throw error;
    });
  }

  static Future<FirebaseAuth> auth() async {
    return FirebaseAuth.instanceFor(app: await app());
  }

  static Future<FirebaseFirestore> firestore() async {
    return FirebaseFirestore.instanceFor(app: await app());
  }

  static Future<FirebaseStorage> storage() async {
    return FirebaseStorage.instanceFor(app: await app());
  }

  static Future<FirebaseApp> _crearApp() async {
    for (final existente in Firebase.apps) {
      if (existente.name == _nombreApp) {
        return existente;
      }
    }

    final nueva = await Firebase.initializeApp(
      name: _nombreApp,
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Sin caché: si no hay internet, guardar falla y el administrador lo ve,
    // en lugar de creer que el cambio quedó guardado.
    FirebaseFirestore.instanceFor(app: nueva).settings =
        const Settings(persistenceEnabled: false);

    return nueva;
  }
}
