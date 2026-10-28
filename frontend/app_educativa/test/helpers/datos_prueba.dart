import 'package:app_educativa/core/database/app_database.dart';
import 'package:app_educativa/features/modulos/domain/estado_descarga.dart';
import 'package:app_educativa/features/modulos/domain/modulo.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Base SQLite real en memoria (vía ffi); ciérrala en tearDown con cerrarBase.
AppDatabase crearBaseEnMemoria() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  return AppDatabase.conRuta(inMemoryDatabasePath);
}

Future<void> cerrarBase(AppDatabase base) async {
  await (await base.database).close();
}

Modulo moduloDePrueba({
  String id = 'lg-grado-3-01',
  String nombre = 'Lenguaje - Módulo 1',
  String area = 'Lenguaje',
  int grado = 3,
  bool estaHabilitado = true,
  EstadoDescarga estado = EstadoDescarga.noDescargado,
  String? rutaLocal,
  DateTime? fechaDescarga,
  int version = 1,
  int? versionDescargada,
}) {
  return Modulo(
    id: id,
    nombre: nombre,
    area: area,
    grado: grado,
    descripcion: 'Descripción de $nombre',
    version: version,
    estaHabilitado: estaHabilitado,
    contenidos: const ['El cuento', 'Los personajes'],
    estadoDescarga: estado,
    rutaLocal: rutaLocal,
    fechaDescarga: fechaDescarga,
    // Por defecto, un módulo descargado tiene la misma versión del catálogo.
    versionDescargada: versionDescargada ??
        (estado == EstadoDescarga.descargado ? version : null),
  );
}
