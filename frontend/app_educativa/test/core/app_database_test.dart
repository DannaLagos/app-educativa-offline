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

  test('migrar de la versión 2 a la actual conserva perfil y administrador',
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

    expect(await db.getVersion(), AppDatabase.versionEsquema);
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
        'progreso_lectura',
        'progreso_actividad',
        'estado_sincronizacion',
      ]),
    );

    await db.close();
  });

  test('migrar de la versión 3 a la actual conserva las descargas y su progreso',
      () async {
    final ruta = join(carpeta.path, 'v3.db');

    // Esquema de la versión 3 (con las tablas de módulos de HU02-HU05).
    final v3 = await openDatabase(
      ruta,
      version: 3,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE perfil_estudiante (id TEXT PRIMARY KEY, nombre TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE superadministrador (id TEXT PRIMARY KEY, '
          'usuario TEXT NOT NULL UNIQUE, password_hash TEXT NOT NULL, '
          'sal TEXT NOT NULL)',
        );
        await db.execute(
          "CREATE TABLE modulo (id TEXT PRIMARY KEY, nombre TEXT NOT NULL, "
          "area TEXT NOT NULL, grado INTEGER NOT NULL, "
          "descripcion TEXT NOT NULL, version INTEGER NOT NULL, "
          "habilitado INTEGER NOT NULL, contenidos TEXT NOT NULL DEFAULT '[]', "
          "estado_descarga TEXT NOT NULL DEFAULT 'no_descargado', "
          "ruta_local TEXT, fecha_descarga TEXT)",
        );
        await db.execute(
          'CREATE TABLE progreso_modulo (id TEXT PRIMARY KEY, '
          'perfil_id TEXT NOT NULL, modulo_id TEXT NOT NULL, '
          'porcentaje INTEGER NOT NULL DEFAULT 0, ultima_actualizacion TEXT, '
          'UNIQUE (perfil_id, modulo_id))',
        );
        await db.insert('modulo', {
          'id': 'cs-grado-1',
          'nombre': 'Ciencias Sociales',
          'area': 'Ciencias Sociales',
          'grado': 1,
          'descripcion': 'D',
          'version': 2,
          'habilitado': 1,
          'estado_descarga': 'descargado',
          'ruta_local': '/datos/modulos/cs-grado-1',
        });
        await db.insert('progreso_modulo', {
          'id': 'pr-1',
          'perfil_id': 'p1',
          'modulo_id': 'cs-grado-1',
          'porcentaje': 30,
        });
      },
    );
    await v3.close();

    final db = await AppDatabase.conRuta(ruta).database;
    final modulo = (await db.query('modulo')).single;

    expect(await db.getVersion(), AppDatabase.versionEsquema);
    expect(modulo['estado_descarga'], 'descargado');
    expect(modulo['ruta_local'], '/datos/modulos/cs-grado-1');
    // Descargado antes de registrar versiones: queda sin versión conocida.
    expect(modulo['version_descargada'], isNull);
    expect(await db.query('progreso_modulo'), hasLength(1));

    await db.close();
  });

  test('migrar de la versión 4 a la actual crea las tablas de progreso '
      '(HU06) y de sincronización (HU11) sin perder el progreso anterior',
      () async {
    final ruta = join(carpeta.path, 'v4.db');

    // Base tal como queda con el código del Sprint 1 (versión 4).
    final v4 = await AppDatabaseV4.crear(ruta);
    await v4.insert('progreso_modulo', {
      'id': 'pr-1',
      'perfil_id': 'p1',
      'modulo_id': 'cs-grado-1',
      'porcentaje': 30,
    });
    await v4.close();

    final db = await AppDatabase.conRuta(ruta).database;

    expect(await db.getVersion(), AppDatabase.versionEsquema);
    final anterior = (await db.query('progreso_modulo')).single;
    expect(anterior['porcentaje'], 30);
    // Lo que ya existía queda pendiente de sincronizar (HU11).
    expect(anterior['sincronizado'], 0);
    expect(await db.query('progreso_lectura'), isEmpty);
    expect(await db.query('progreso_actividad'), isEmpty);
    expect(await db.query('estado_sincronizacion'), isEmpty);

    await db.close();
  });
}

/// Esquema exacto de la versión 4, para probar la migración a la 5.
class AppDatabaseV4 {
  static Future<Database> crear(String ruta) {
    return openDatabase(
      ruta,
      version: 4,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE perfil_estudiante (id TEXT PRIMARY KEY, nombre TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE superadministrador (id TEXT PRIMARY KEY, '
          'usuario TEXT NOT NULL UNIQUE, password_hash TEXT NOT NULL, '
          'sal TEXT NOT NULL)',
        );
        await db.execute(
          "CREATE TABLE modulo (id TEXT PRIMARY KEY, nombre TEXT NOT NULL, "
          "area TEXT NOT NULL, grado INTEGER NOT NULL, "
          "descripcion TEXT NOT NULL, version INTEGER NOT NULL, "
          "habilitado INTEGER NOT NULL, contenidos TEXT NOT NULL DEFAULT '[]', "
          "estado_descarga TEXT NOT NULL DEFAULT 'no_descargado', "
          "ruta_local TEXT, fecha_descarga TEXT, version_descargada INTEGER)",
        );
        await db.execute(
          'CREATE TABLE progreso_modulo (id TEXT PRIMARY KEY, '
          'perfil_id TEXT NOT NULL, modulo_id TEXT NOT NULL, '
          'porcentaje INTEGER NOT NULL DEFAULT 0, ultima_actualizacion TEXT, '
          'UNIQUE (perfil_id, modulo_id))',
        );
      },
    );
  }
}
