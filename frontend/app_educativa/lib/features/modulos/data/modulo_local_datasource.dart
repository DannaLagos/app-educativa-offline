import '../../../core/database/app_database.dart';
import '../domain/estado_descarga.dart';
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
          ..remove('fecha_descarga')
          ..remove('version_descargada');

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

  /// Módulos en un estado de descarga, habilitados o no.
  Future<List<Modulo>> obtenerPorEstado(EstadoDescarga estado) async {
    final db = await _appDatabase.database;

    final filas = await db.query(
      'modulo',
      where: 'estado_descarga = ?',
      whereArgs: [estado.valor],
      orderBy: 'area, grado, nombre',
    );

    return filas.map(Modulo.fromMap).toList();
  }

  /// Cambia el estado de descarga. La ruta, la fecha y la versión solo se
  /// guardan cuando el módulo queda descargado; en otro estado se limpian.
  Future<void> actualizarEstadoDescarga(
    String id,
    EstadoDescarga estado, {
    String? rutaLocal,
    DateTime? fechaDescarga,
    int? versionDescargada,
  }) async {
    final db = await _appDatabase.database;
    final descargado = estado == EstadoDescarga.descargado;

    await db.update(
      'modulo',
      {
        'estado_descarga': estado.valor,
        'ruta_local': descargado ? rutaLocal : null,
        'fecha_descarga': descargado ? fechaDescarga?.toIso8601String() : null,
        'version_descargada': descargado ? versionDescargada : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Pasa a "error" las descargas que quedaron en "descargando" (la app se
  /// cerró a mitad de una descarga).
  Future<void> marcarDescargasInterrumpidas() async {
    final db = await _appDatabase.database;

    await db.update(
      'modulo',
      {'estado_descarga': EstadoDescarga.error.valor},
      where: 'estado_descarga = ?',
      whereArgs: [EstadoDescarga.descargando.valor],
    );
  }
}
