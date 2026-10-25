import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../features/admin/data/admin_config.dart';
import '../security/password_hasher.dart';

class AppDatabase {
  AppDatabase._() : _ruta = null;

  AppDatabase.conRuta(String ruta) : _ruta = ruta;

  static final AppDatabase instance = AppDatabase._();

  static const int versionEsquema = 4;
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
