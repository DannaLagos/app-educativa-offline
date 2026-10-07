import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../features/admin/data/admin_config.dart';
import '../security/password_hasher.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'app_educativa.db',
    );

    return openDatabase(
      path,
      version: 2,
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
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _crearTablaSuperadministrador(db);
    }
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
