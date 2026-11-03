import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../mascota/domain/mascota.dart';
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

  /// Para los perfiles que se crearon antes de que existieran las mascotas.
  Future<void> guardarMascota(
    String perfilId,
    EspecieMascota mascota, {
    String? nombre,
  }) async {
    final baseDatos = await _appDatabase.database;

    await baseDatos.update(
      'perfil_estudiante',
      {'mascota': mascota.name, 'nombre_mascota': nombre},
      where: 'id = ?',
      whereArgs: [perfilId],
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
