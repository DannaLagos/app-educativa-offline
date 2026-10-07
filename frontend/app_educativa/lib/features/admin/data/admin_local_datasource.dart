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
    final db = await _appDatabase.database;

    final resultado = await db.query(
      'superadministrador',
      where: 'usuario = ?',
      whereArgs: [usuario],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    final fila = resultado.first;

    final esValida = PasswordHasher.verificar(
      password,
      fila['sal'] as String,
      fila['password_hash'] as String,
    );

    if (!esValida) {
      return null;
    }

    return Superadministrador.fromMap(fila);
  }
}
