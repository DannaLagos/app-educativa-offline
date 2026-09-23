import '../../../core/database/app_database.dart';
import '../domain/perfil_estudiante.dart';
import 'package:sqflite/sqflite.dart';

class PerfilLocalDataSource {
  final AppDatabase _appDatabase;

  PerfilLocalDataSource({
    AppDatabase? appDatabase,
  }) : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<void> guardarPerfil(PerfilEstudiante perfil) async {
    final db = await _appDatabase.database;

    await db.insert(
      'perfil_estudiante',
      perfil.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PerfilEstudiante?> obtenerPerfil() async {
    final db = await _appDatabase.database;

    final resultado = await db.query(
      'perfil_estudiante',
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return PerfilEstudiante.fromMap(resultado.first);
  }

  Future<bool> existePerfil() async {
    final perfil = await obtenerPerfil();

    return perfil != null;
  }

  Future<void> eliminarPerfil() async {
    final db = await _appDatabase.database;

    await db.delete('perfil_estudiante');
  }
}