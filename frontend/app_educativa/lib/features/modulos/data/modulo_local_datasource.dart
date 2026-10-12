import '../../../core/database/app_database.dart';
import '../domain/modulo.dart';

class ModuloLocalDataSource {
  final AppDatabase _appDatabase;

  ModuloLocalDataSource({
    AppDatabase? appDatabase,
  }) : _appDatabase = appDatabase ?? AppDatabase.instance;

  /// Guarda el catálogo recibido del servidor sin perder el estado de
  /// descarga local. Los módulos que ya no vienen en el catálogo quedan
  /// deshabilitados (no se borran: pueden estar descargados).
  Future<void> guardarCatalogo(List<Modulo> modulos) async {
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      for (final modulo in modulos) {
        final datosCatalogo = modulo.toMap()
          ..remove('estado_descarga')
          ..remove('ruta_local')
          ..remove('fecha_descarga');

        final actualizados = await txn.update(
          'modulo',
          datosCatalogo,
          where: 'id = ?',
          whereArgs: [modulo.id],
        );

        if (actualizados == 0) {
          await txn.insert('modulo', modulo.toMap());
        }
      }

      final ids = modulos.map((modulo) => modulo.id).toList();

      await txn.update(
        'modulo',
        {'habilitado': 0},
        where: ids.isEmpty
            ? null
            : 'id NOT IN (${List.filled(ids.length, '?').join(', ')})',
        whereArgs: ids.isEmpty ? null : ids,
      );
    });
  }

  /// Módulos habilitados, ordenados por área, grado y nombre.
  Future<List<Modulo>> obtenerCatalogo() async {
    final db = await _appDatabase.database;

    final filas = await db.query(
      'modulo',
      where: 'habilitado = 1',
      orderBy: 'area, grado, nombre',
    );

    return filas.map(Modulo.fromMap).toList();
  }

  Future<Modulo?> obtenerModulo(String id) async {
    final db = await _appDatabase.database;

    final filas = await db.query(
      'modulo',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (filas.isEmpty) {
      return null;
    }

    return Modulo.fromMap(filas.first);
  }
}
