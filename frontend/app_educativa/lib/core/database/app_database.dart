import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../features/admin/data/admin_config.dart';
import '../security/password_hasher.dart';

class AppDatabase {
  AppDatabase._() : _ruta = null;

  AppDatabase.conRuta(String ruta) : _ruta = ruta;

  static final AppDatabase instance = AppDatabase._();

  static const int versionEsquema = 6;
  static const String _nombreArchivo = 'app_educativa.db';

  final String? _ruta;

  Database? _baseDatos;

  Future<Database> get database async {
    return _baseDatos ??= await _abrirBaseDatos();
  }

  Future<Database> _abrirBaseDatos() async {
    final ruta = _ruta ?? join(await getDatabasesPath(), _nombreArchivo);

    return openDatabase(
      ruta,
      version: versionEsquema,
      onCreate: _crearEsquema,
      onUpgrade: _migrarEsquema,
    );
  }

  Future<void> _crearEsquema(Database baseDatos, int version) async {
    await _crearTablaPerfilEstudiante(baseDatos);
    await _crearTablaSuperadministrador(baseDatos);
    await _crearTablasModulos(baseDatos);
    await _agregarVersionDescargada(baseDatos);
    await _crearTablasProgreso(baseDatos);
    await _crearTablaEstadoSincronizacion(baseDatos);
  }

  Future<void> _migrarEsquema(
    Database baseDatos,
    int versionAnterior,
    int versionNueva,
  ) async {
    if (versionAnterior < 2) {
      await _crearTablaSuperadministrador(baseDatos);
    }

    if (versionAnterior < 3) {
      await _crearTablasModulos(baseDatos);
    }

    if (versionAnterior < 4) {
      await _agregarVersionDescargada(baseDatos);
    }

    if (versionAnterior < 5) {
      await _crearTablasProgreso(baseDatos);
    }

    if (versionAnterior < 6) {
      await _crearTablaEstadoSincronizacion(baseDatos);
    }
  }

  /// HU11: cuándo se sincronizó por última vez el progreso de cada perfil.
  /// Una fila por perfil: sincronizar otra vez la reemplaza, no la duplica.
  Future<void> _crearTablaEstadoSincronizacion(Database baseDatos) async {
    await baseDatos.execute('''
      CREATE TABLE estado_sincronizacion (
        perfil_id TEXT PRIMARY KEY,
        ultima_sincronizacion TEXT NOT NULL,
        registros_enviados INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// HU06: progreso del estudiante guardado en el dispositivo.
  ///
  /// - progreso_modulo (ya existía): resumen por módulo.
  /// - progreso_lectura: página donde va en cada documento del módulo.
  /// - progreso_actividad: resultado de cada actividad o juego (HU07).
  ///
  /// La columna `sincronizado` (0 = pendiente, 1 = enviado): cada cambio la
  /// pone en 0 y la sincronización (HU10/HU11) la pasa a 1.
  /// Ninguna tabla tiene clave foránea hacia `modulo`: eliminar una descarga
  /// nunca borra el progreso (HU05).
  Future<void> _crearTablasProgreso(Database baseDatos) async {
    await baseDatos.execute(
      'ALTER TABLE progreso_modulo '
      'ADD COLUMN sincronizado INTEGER NOT NULL DEFAULT 0',
    );

    await baseDatos.execute('''
      CREATE TABLE progreso_lectura (
        id TEXT PRIMARY KEY,
        perfil_id TEXT NOT NULL,
        modulo_id TEXT NOT NULL,
        recurso TEXT NOT NULL,
        ultima_pagina INTEGER NOT NULL,
        pagina_maxima INTEGER NOT NULL,
        total_paginas INTEGER NOT NULL,
        ultima_actualizacion TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        UNIQUE (perfil_id, modulo_id, recurso)
      )
    ''');

    await baseDatos.execute('''
      CREATE TABLE progreso_actividad (
        id TEXT PRIMARY KEY,
        perfil_id TEXT NOT NULL,
        modulo_id TEXT NOT NULL,
        actividad_id TEXT NOT NULL,
        completada INTEGER NOT NULL DEFAULT 0,
        puntaje INTEGER NOT NULL DEFAULT 0,
        intentos INTEGER NOT NULL DEFAULT 0,
        ultima_actualizacion TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        UNIQUE (perfil_id, modulo_id, actividad_id)
      )
    ''');
  }

  Future<void> _crearTablaPerfilEstudiante(Database baseDatos) async {
    await baseDatos.execute('''
      CREATE TABLE perfil_estudiante (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL
      )
    ''');
  }

  // Los módulos descargados antes de esta migración quedan en NULL (desactualizados).
  Future<void> _agregarVersionDescargada(Database baseDatos) async {
    await baseDatos.execute(
      'ALTER TABLE modulo ADD COLUMN version_descargada INTEGER',
    );
  }

  Future<void> _crearTablasModulos(Database baseDatos) async {
    await baseDatos.execute('''
      CREATE TABLE modulo (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        area TEXT NOT NULL,
        grado INTEGER NOT NULL,
        descripcion TEXT NOT NULL,
        version INTEGER NOT NULL,
        habilitado INTEGER NOT NULL,
        contenidos TEXT NOT NULL DEFAULT '[]',
        estado_descarga TEXT NOT NULL DEFAULT 'no_descargado',
        ruta_local TEXT,
        fecha_descarga TEXT
      )
    ''');

    // Sin clave foránea en cascada: eliminar una descarga nunca borra el progreso.
    await baseDatos.execute('''
      CREATE TABLE progreso_modulo (
        id TEXT PRIMARY KEY,
        perfil_id TEXT NOT NULL,
        modulo_id TEXT NOT NULL,
        porcentaje INTEGER NOT NULL DEFAULT 0,
        ultima_actualizacion TEXT,
        UNIQUE (perfil_id, modulo_id)
      )
    ''');
  }

  Future<void> _crearTablaSuperadministrador(Database baseDatos) async {
    await baseDatos.execute('''
      CREATE TABLE superadministrador (
        id TEXT PRIMARY KEY,
        usuario TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        sal TEXT NOT NULL
      )
    ''');

    await _insertarSuperadministradorInicial(baseDatos);
  }

  Future<void> _insertarSuperadministradorInicial(Database baseDatos) async {
    final sal = PasswordHasher.generarSal();

    await baseDatos.insert(
      'superadministrador',
      {
        'id': const Uuid().v4(),
        'usuario': AdminConfig.usuarioInicial,
        'password_hash': PasswordHasher.hashear(
          AdminConfig.passwordInicial,
          sal,
        ),
        'sal': sal,
      },
    );
  }
}
