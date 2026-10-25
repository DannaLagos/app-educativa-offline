import '../../../core/database/app_database.dart';
import '../../../core/security/password_hasher.dart';
import '../domain/superadministrador.dart';

class AdminLocalDataSource {
  final AppDatabase _appDatabase;

  AdminLocalDataSource({
    AppDatabase? appDatabase,
  }) : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Superadministrador?> autenticar(
    String usuario,
    String password,
  ) async {
    final fila = await _buscarPorUsuario(usuario);

    if (fila == null || !_esPasswordValida(fila, password)) {
      return null;
    }

    return Superadministrador.fromMap(fila);
  }

  Future<Map<String, Object?>?> _buscarPorUsuario(String usuario) async {
    final baseDatos = await _appDatabase.database;

    final filas = await baseDatos.query(
      'superadministrador',
      where: 'usuario = ?',
      whereArgs: [usuario],
      limit: 1,
    );

    return filas.isEmpty ? null : filas.first;
  }

  bool _esPasswordValida(Map<String, Object?> fila, String password) {
    return PasswordHasher.verificar(
      password,
      fila['sal'] as String,
      fila['password_hash'] as String,
    );
  }
}
