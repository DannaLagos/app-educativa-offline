import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/perfil_estudiante.dart';

class PerfilLocalDataSource {
  final AppDatabase _appDatabase;

  PerfilLocalDataSource({
    AppDatabase? appDatabase,
  }) : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<void> guardarPerfil(PerfilEstudiante perfil) async {
    final baseDatos = await _appDatabase.database;

    await baseDatos.insert(
      'perfil_estudiante',
      perfil.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PerfilEstudiante?> obtenerPerfil() async {
    final baseDatos = await _appDatabase.database;

    final filas = await baseDatos.query(
      'perfil_estudiante',
      limit: 1,
    );

    if (filas.isEmpty) {
      return null;
    }

    return PerfilEstudiante.fromMap(filas.first);
  }
}
