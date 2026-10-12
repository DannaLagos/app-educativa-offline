import 'package:app_educativa/core/database/app_database.dart';
import 'package:app_educativa/features/modulos/domain/estado_descarga.dart';
import 'package:app_educativa/features/modulos/domain/modulo.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Base SQLite real en memoria (vía ffi) con el mismo esquema de la app.
/// Recuerda cerrarla en tearDown con [cerrarBase].
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
  bool habilitado = true,
  EstadoDescarga estado = EstadoDescarga.noDescargado,
  String? rutaLocal,
  DateTime? fechaDescarga,
}) {
  return Modulo(
    id: id,
    nombre: nombre,
    area: area,
    grado: grado,
    descripcion: 'Descripción de $nombre',
    version: 1,
    habilitado: habilitado,
    contenidos: const ['El cuento', 'Los personajes'],
    estadoDescarga: estado,
    rutaLocal: rutaLocal,
    fechaDescarga: fechaDescarga,
  );
}
