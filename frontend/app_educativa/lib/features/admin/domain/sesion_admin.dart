import 'superadministrador.dart';

// La sesión vive solo en memoria: al cerrar sesión o cerrar la app,
// el superadministrador debe autenticarse de nuevo.
class SesionAdmin {
  SesionAdmin._();

  static final SesionAdmin instance = SesionAdmin._();

  Superadministrador? _actual;

  Superadministrador? get actual => _actual;

  bool get estaActiva => _actual != null;

  void iniciar(Superadministrador admin) {
    _actual = admin;
  }

  void cerrar() {
    _actual = null;
  }
}
