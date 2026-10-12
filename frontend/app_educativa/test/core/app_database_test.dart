import 'dart:io';

import 'package:app_educativa/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory carpeta;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    carpeta = await Directory.systemTemp.createTemp('app_db_');
  });

  tearDown(() => carpeta.delete(recursive: true));

  test('migrar de la versión 2 a la 3 conserva perfil y administrador',
      () async {
    final ruta = join(carpeta.path, 'app_educativa.db');

    // Base tal como quedaba en la versión 2.
    final v2 = await openDatabase(
      ruta,
      version: 2,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE perfil_estudiante (id TEXT PRIMARY KEY, nombre TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE superadministrador (id TEXT PRIMARY KEY, '
          'usuario TEXT NOT NULL UNIQUE, password_hash TEXT NOT NULL, '
          'sal TEXT NOT NULL)',
        );
        await db.insert('perfil_estudiante', {'id': 'p1', 'nombre': 'Ana'});
        await db.insert('superadministrador', {
          'id': 'a1',
          'usuario': 'admin',
          'password_hash': 'hash',
          'sal': 'sal',
        });
      },
    );
    await v2.close();

    final base = AppDatabase.conRuta(ruta);
    final db = await base.database;

    expect(await db.getVersion(), 3);
    expect(await db.query('perfil_estudiante'), [
      {'id': 'p1', 'nombre': 'Ana'},
    ]);
    expect(await db.query('superadministrador'), hasLength(1));
    expect(await db.query('modulo'), isEmpty);
    expect(await db.query('progreso_modulo'), isEmpty);

    await db.close();
  });

  test('una instalación nueva crea todas las tablas', () async {
    final base = AppDatabase.conRuta(join(carpeta.path, 'nueva.db'));
    final db = await base.database;

    final tablas = (await db.query(
      'sqlite_master',
      columns: ['name'],
      where: "type = 'table'",
    ))
        .map((fila) => fila['name'])
        .toSet();

    expect(
      tablas,
      containsAll([
        'perfil_estudiante',
        'superadministrador',
        'modulo',
        'progreso_modulo',
      ]),
    );

    await db.close();
  });
}
