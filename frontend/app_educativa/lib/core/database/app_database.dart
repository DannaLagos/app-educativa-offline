import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../features/admin/data/admin_config.dart';
import '../security/password_hasher.dart';

class AppDatabase {
  AppDatabase._() : _ruta = null;

  /// Abre la base en [ruta]. Pensado para pruebas (por ejemplo,
  /// `inMemoryDatabasePath` con sqflite_common_ffi).
  AppDatabase.conRuta(String ruta) : _ruta = ruta;

  static final AppDatabase instance = AppDatabase._();

  static const int version = 4;

  final String? _ruta;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = _ruta ??
        join(
          await getDatabasesPath(),
          'app_educativa.db',
        );

    return openDatabase(
      path,
      version: version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE perfil_estudiante (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL
      )
    ''');

    await _crearTablaSuperadministrador(db);
    await _crearTablasModulos(db);
    await _agregarVersionDescargada(db);
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _crearTablaSuperadministrador(db);
    }

    if (oldVersion < 3) {
      await _crearTablasModulos(db);
    }

    if (oldVersion < 4) {
      await _agregarVersionDescargada(db);
    }
  }

  /// Versión del contenido que está guardado en el dispositivo, para avisar
  /// cuando el catálogo trae una más nueva. Los módulos descargados antes de
  /// esta migración quedan en NULL y se tratan como desactualizados.
  Future<void> _agregarVersionDescargada(Database db) async {
    await db.execute(
      'ALTER TABLE modulo ADD COLUMN version_descargada INTEGER',
    );
  }

  Future<void> _crearTablasModulos(Database db) async {
    // Caché del catálogo y estado de descarga de cada módulo.
    await db.execute('''
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

    // Progreso del estudiante. Va separado de modulo y sin clave foránea
    // en cascada: eliminar la descarga de un módulo nunca debe borrarlo.
    // Se llena a partir del Sprint 2.
    await db.execute('''
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

  Future<void> _crearTablaSuperadministrador(Database db) async {
    await db.execute('''
      CREATE TABLE superadministrador (
        id TEXT PRIMARY KEY,
        usuario TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        sal TEXT NOT NULL
      )
    ''');

    final sal = PasswordHasher.generarSal();

    await db.insert(
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
