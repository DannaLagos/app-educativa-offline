import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/estado_descarga.dart';
import '../domain/modulo.dart';

class ModuloLocalDataSource {
  static const String _tabla = 'modulo';
  static const String _ordenCatalogo = 'area, grado, nombre';
  static const List<String> _columnasDeDescarga = [
    'estado_descarga',
    'ruta_local',
    'fecha_descarga',
    'version_descargada',
  ];

  final AppDatabase _appDatabase;

  ModuloLocalDataSource({
    AppDatabase? appDatabase,
  }) : _appDatabase = appDatabase ?? AppDatabase.instance;

  // Conserva el estado de descarga; los módulos ausentes se deshabilitan, no se borran.
  Future<void> guardarCatalogo(List<Modulo> modulos) async {
    final baseDatos = await _appDatabase.database;

    await baseDatos.transaction((transaccion) async {
      for (final modulo in modulos) {
        await _guardarDatosDeCatalogo(transaccion, modulo);
      }

      await _deshabilitarAusentes(
        transaccion,
        modulos.map((modulo) => modulo.id).toList(),
      );
    });
  }

  Future<List<Modulo>> obtenerCatalogo() async {
    final baseDatos = await _appDatabase.database;

    final filas = await baseDatos.query(
      _tabla,
      where: 'habilitado = 1',
      orderBy: _ordenCatalogo,
    );

    return filas.map(Modulo.fromMap).toList();
  }

  Future<Modulo?> obtenerModulo(String id) async {
    final baseDatos = await _appDatabase.database;

    final filas = await baseDatos.query(
      _tabla,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (filas.isEmpty) {
      return null;
    }

    return Modulo.fromMap(filas.first);
  }

  Future<List<Modulo>> obtenerPorEstado(EstadoDescarga estado) async {
    final baseDatos = await _appDatabase.database;

    final filas = await baseDatos.query(
      _tabla,
      where: 'estado_descarga = ?',
      whereArgs: [estado.valor],
      orderBy: _ordenCatalogo,
    );

    return filas.map(Modulo.fromMap).toList();
  }

  // La ruta, la fecha y la versión solo se conservan en el estado "descargado".
  Future<void> actualizarEstadoDescarga(
    String id,
    EstadoDescarga estado, {
    String? rutaLocal,
    DateTime? fechaDescarga,
    int? versionDescargada,
  }) async {
    final baseDatos = await _appDatabase.database;
    final estaDescargado = estado == EstadoDescarga.descargado;

    await baseDatos.update(
      _tabla,
      {
        'estado_descarga': estado.valor,
        'ruta_local': estaDescargado ? rutaLocal : null,
        'fecha_descarga':
            estaDescargado ? fechaDescarga?.toIso8601String() : null,
        'version_descargada': estaDescargado ? versionDescargada : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> marcarDescargasInterrumpidas() async {
    final baseDatos = await _appDatabase.database;

    await baseDatos.update(
      _tabla,
      {'estado_descarga': EstadoDescarga.error.valor},
      where: 'estado_descarga = ?',
      whereArgs: [EstadoDescarga.descargando.valor],
    );
  }

  Future<void> _guardarDatosDeCatalogo(
    Transaction transaccion,
    Modulo modulo,
  ) async {
    final datosCatalogo = modulo.toMap()
      ..removeWhere((columna, _) => _columnasDeDescarga.contains(columna));

    final filasActualizadas = await transaccion.update(
      _tabla,
      datosCatalogo,
      where: 'id = ?',
      whereArgs: [modulo.id],
    );

    if (filasActualizadas == 0) {
      await transaccion.insert(_tabla, modulo.toMap());
    }
  }

  Future<void> _deshabilitarAusentes(
    Transaction transaccion,
    List<String> idsEnCatalogo,
  ) async {
    final hayIds = idsEnCatalogo.isNotEmpty;
    final marcadores = List.filled(idsEnCatalogo.length, '?').join(', ');

    await transaccion.update(
      _tabla,
      {'habilitado': 0},
      where: hayIds ? 'id NOT IN ($marcadores)' : null,
      whereArgs: hayIds ? idsEnCatalogo : null,
    );
  }
}
