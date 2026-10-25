import 'dart:io';

import 'package:app_educativa/core/database/app_database.dart';
import 'package:app_educativa/features/progreso/data/progreso_local_datasource.dart';
import 'package:app_educativa/features/progreso/domain/resultado_actividad.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/datos_prueba.dart';

const _perfil = 'perfil-1';
const _modulo = 'cs-grado-1';
const _pdf = 'CS_Grado01_Fichas.pdf';

void main() {
  late AppDatabase base;
  late ProgresoLocalDataSource local;
  final ahora = DateTime(2026, 10, 25, 10);

  setUp(() {
    base = crearBaseEnMemoria();
    local = ProgresoLocalDataSource(appDatabase: base, ahora: () => ahora);
  });

  tearDown(() => cerrarBase(base));

  group('HU06 CA1: guarda el avance del estudiante', () {
    test('sin progreso guardado, el módulo aparece sin iniciar', () async {
      final progreso = await local.obtenerProgresoModulo(
        perfilId: _perfil,
        moduloId: _modulo,
      );

      expect(progreso.estaIniciado, isFalse);
      expect(progreso.porcentaje, 0);
    });

    test('guarda la página leída y calcula el porcentaje', () async {
      await local.guardarLectura(
        perfilId: _perfil,
        moduloId: _modulo,
        recurso: _pdf,
        pagina: 5,
        totalPaginas: 20,
      );

      final progreso = await local.obtenerProgresoModulo(
        perfilId: _perfil,
        moduloId: _modulo,
      );
      final lectura = progreso.lecturaDe(_pdf)!;

      expect(progreso.estaIniciado, isTrue);
      expect(lectura.ultimaPagina, 5);
      expect(lectura.paginaMaxima, 5);
      expect(lectura.totalPaginas, 20);
      expect(progreso.porcentaje, 25);
      expect(progreso.ultimaActualizacion, ahora);
    });

    test('volver a una página anterior no reduce el avance', () async {
      for (final pagina in [3, 10, 4]) {
        await local.guardarLectura(
          perfilId: _perfil,
          moduloId: _modulo,
          recurso: _pdf,
          pagina: pagina,
          totalPaginas: 20,
        );
      }

      final progreso = await local.obtenerProgresoModulo(
        perfilId: _perfil,
        moduloId: _modulo,
      );
      final lectura = progreso.lecturaDe(_pdf)!;

      expect(lectura.ultimaPagina, 4, reason: 'para continuar donde iba');
      expect(lectura.paginaMaxima, 10);
      expect(progreso.porcentaje, 50);
    });

    test('una página fuera de rango se ajusta al documento', () async {
      await local.guardarLectura(
        perfilId: _perfil,
        moduloId: _modulo,
        recurso: _pdf,
        pagina: 99,
        totalPaginas: 20,
      );

      final lectura = (await local.obtenerProgresoModulo(
        perfilId: _perfil,
        moduloId: _modulo,
      ))
          .lecturaDe(_pdf)!;

      expect(lectura.ultimaPagina, 20);
    });

    test('con varios documentos, el porcentaje es el promedio', () async {
      await local.guardarLectura(
        perfilId: _perfil,
        moduloId: _modulo,
        recurso: 'a.pdf',
        pagina: 10,
        totalPaginas: 10,
      );
      await local.guardarLectura(
        perfilId: _perfil,
        moduloId: _modulo,
        recurso: 'b.pdf',
        pagina: 0,
        totalPaginas: 10,
      );

      final progreso = await local.obtenerProgresoModulo(
        perfilId: _perfil,
        moduloId: _modulo,
      );

      // a.pdf 100 %, b.pdf 10 % (la página mínima es la 1).
      expect(progreso.porcentaje, 55);
    });

    test('guarda el resultado de una actividad', () async {
      await local.registrarResultado(
        perfilId: _perfil,
        resultado: const ResultadoActividad(
          moduloId: _modulo,
          actividadId: 'emparejar-familia',
          completada: true,
          puntaje: 80,
        ),
      );

      final progreso = await local.obtenerProgresoModulo(
        perfilId: _perfil,
        moduloId: _modulo,
      );
      final actividad = progreso.actividadDe('emparejar-familia')!;

      expect(progreso.estaIniciado, isTrue);
      expect(progreso.actividadesCompletadas, 1);
      expect(actividad.completada, isTrue);
      expect(actividad.puntaje, 80);
      expect(actividad.intentos, 1);
    });

    test('repetir una actividad suma intentos y conserva el mejor puntaje',
        () async {
      Future<void> jugar({required bool completada, required int puntaje}) {
        return local.registrarResultado(
          perfilId: _perfil,
          resultado: ResultadoActividad(
            moduloId: _modulo,
            actividadId: 'ordenar-rutina',
            completada: completada,
            puntaje: puntaje,
          ),
        );
      }

      await jugar(completada: true, puntaje: 90);
      await jugar(completada: false, puntaje: 40);

      final actividad = (await local.obtenerProgresoModulo(
        perfilId: _perfil,
        moduloId: _modulo,
      ))
          .actividadDe('ordenar-rutina')!;

      expect(actividad.intentos, 2);
      expect(actividad.puntaje, 90);
      expect(actividad.completada, isTrue,
          reason: 'una actividad completada no vuelve a quedar pendiente');
    });

    test('el progreso de un perfil no se mezcla con el de otro', () async {
      await local.guardarLectura(
        perfilId: _perfil,
        moduloId: _modulo,
        recurso: _pdf,
        pagina: 8,
        totalPaginas: 10,
      );

      final otro = await local.obtenerProgresoModulo(
        perfilId: 'perfil-2',
        moduloId: _modulo,
      );

      expect(otro.estaIniciado, isFalse);
    });
  });

  test('cada cambio queda pendiente de sincronizar (preparado para HU11)',
      () async {
    await local.guardarLectura(
      perfilId: _perfil,
      moduloId: _modulo,
      recurso: _pdf,
      pagina: 2,
      totalPaginas: 10,
    );
    await local.registrarResultado(
      perfilId: _perfil,
      resultado: const ResultadoActividad(
        moduloId: _modulo,
        actividadId: 'quiz-1',
        completada: true,
        puntaje: 100,
      ),
    );

    final db = await base.database;
    for (final tabla in [
      'progreso_modulo',
      'progreso_lectura',
      'progreso_actividad',
    ]) {
      final fila = (await db.query(tabla)).single;
      expect(fila['sincronizado'], 0, reason: tabla);
    }
  });

  test('HU06 CA3: el progreso sigue guardado al cerrar y volver a abrir la app',
      () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final carpeta = await Directory.systemTemp.createTemp('progreso_');
    final ruta = join(carpeta.path, 'app_educativa.db');

    // Primera sesión: el estudiante lee y juega, y luego cierra la app.
    final primeraSesion = AppDatabase.conRuta(ruta);
    final antes = ProgresoLocalDataSource(appDatabase: primeraSesion);
    await antes.guardarLectura(
      perfilId: _perfil,
      moduloId: _modulo,
      recurso: _pdf,
      pagina: 7,
      totalPaginas: 14,
    );
    await antes.registrarResultado(
      perfilId: _perfil,
      resultado: const ResultadoActividad(
        moduloId: _modulo,
        actividadId: 'clasificar-normas',
        completada: true,
        puntaje: 70,
      ),
    );
    await cerrarBase(primeraSesion);

    // Segunda sesión: se abre de nuevo el mismo archivo de base de datos.
    final segundaSesion = AppDatabase.conRuta(ruta);
    final progreso = await ProgresoLocalDataSource(appDatabase: segundaSesion)
        .obtenerProgresoModulo(perfilId: _perfil, moduloId: _modulo);

    expect(progreso.lecturaDe(_pdf)!.ultimaPagina, 7);
    expect(progreso.actividadDe('clasificar-normas')!.completada, isTrue);
    expect(progreso.porcentaje, 50);

    await cerrarBase(segundaSesion);
    await carpeta.delete(recursive: true);
  });
}
