import 'dart:math';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/progreso_modulo.dart';
import '../domain/progreso_pendiente.dart';
import '../domain/resultado_actividad.dart';

/// Guarda el progreso del estudiante en SQLite (HU06). Todo es local: no usa
///  y no depende de la red ni del servidor.
class ProgresoLocalDataSource {
  static const String _tablaModulo = 'progreso_modulo';
  static const String _tablaLectura = 'progreso_lectura';
  static const String _tablaActividad = 'progreso_actividad';
  static const String _tablaEstado = 'estado_sincronizacion';

  final AppDatabase _appDatabase;
  final Uuid _uuid;
  final DateTime Function() _ahora;

  ProgresoLocalDataSource({
    AppDatabase? appDatabase,
    Uuid? uuid,
    DateTime Function()? ahora,
  })  : _appDatabase = appDatabase ?? AppDatabase.instance,
        _uuid = uuid ?? const Uuid(),
        _ahora = ahora ?? DateTime.now;

  /// Registra que el estudiante está en [pagina] de [recurso].
  Future<void> guardarLectura({
    required String perfilId,
    required String moduloId,
    required String recurso,
    required int pagina,
    required int totalPaginas,
  }) async {
    if (totalPaginas <= 0) {
      throw ArgumentError.value(totalPaginas, 'totalPaginas');
    }

    final paginaValida = min(max(pagina, 1), totalPaginas);
    final baseDatos = await _appDatabase.database;
    final fecha = _ahora().toIso8601String();

    await baseDatos.transaction((txn) async {
      final filas = await txn.query(
        _tablaLectura,
        columns: ['pagina_maxima'],
        where: 'perfil_id = ? AND modulo_id = ? AND recurso = ?',
        whereArgs: [perfilId, moduloId, recurso],
        limit: 1,
      );

      if (filas.isEmpty) {
        await txn.insert(_tablaLectura, {
          'id': _uuid.v4(),
          'perfil_id': perfilId,
          'modulo_id': moduloId,
          'recurso': recurso,
          'ultima_pagina': paginaValida,
          'pagina_maxima': paginaValida,
          'total_paginas': totalPaginas,
          'ultima_actualizacion': fecha,
          'sincronizado': 0,
        });
      } else {
        final maximaAnterior = filas.first['pagina_maxima'] as int;
        // Si el documento se actualizó y ahora tiene menos páginas, el
        final maxima = min(max(maximaAnterior, paginaValida), totalPaginas);

        await txn.update(
          _tablaLectura,
          {
            'ultima_pagina': paginaValida,
            'pagina_maxima': maxima,
            'total_paginas': totalPaginas,
            'ultima_actualizacion': fecha,
            'sincronizado': 0,
          },
          where: 'perfil_id = ? AND modulo_id = ? AND recurso = ?',
          whereArgs: [perfilId, moduloId, recurso],
        );
      }

      await _actualizarResumen(txn, perfilId, moduloId, fecha);
    });
  }

  /// Guarda el resultado de una actividad. Si ya se había hecho, suma un
  /// intento y conserva el mejor puntaje; una actividad completada no vuelve
  /// a quedar pendiente.
  Future<void> registrarResultado({
    required String perfilId,
    required ResultadoActividad resultado,
  }) async {
    final baseDatos = await _appDatabase.database;
    final fecha = _ahora().toIso8601String();
    const filtro = 'perfil_id = ? AND modulo_id = ? AND actividad_id = ?';
    final argumentos = [perfilId, resultado.moduloId, resultado.actividadId];

    await baseDatos.transaction((txn) async {
      final filas = await txn.query(
        _tablaActividad,
        columns: ['completada', 'puntaje', 'intentos'],
        where: filtro,
        whereArgs: argumentos,
        limit: 1,
      );

      if (filas.isEmpty) {
        await txn.insert(_tablaActividad, {
          'id': _uuid.v4(),
          'perfil_id': perfilId,
          'modulo_id': resultado.moduloId,
          'actividad_id': resultado.actividadId,
          'completada': resultado.completada ? 1 : 0,
          'puntaje': resultado.puntaje,
          'intentos': 1,
          'ultima_actualizacion': fecha,
          'sincronizado': 0,
        });
      } else {
        final anterior = filas.first;

        await txn.update(
          _tablaActividad,
          {
            'completada':
                (anterior['completada'] == 1 || resultado.completada) ? 1 : 0,
            'puntaje': max(anterior['puntaje'] as int, resultado.puntaje),
            'intentos': (anterior['intentos'] as int) + 1,
            'ultima_actualizacion': fecha,
            'sincronizado': 0,
          },
          where: filtro,
          whereArgs: argumentos,
        );
      }

      await _actualizarResumen(txn, perfilId, resultado.moduloId, fecha);
    });
  }

  Future<ProgresoModulo> obtenerProgresoModulo({
    required String perfilId,
    required String moduloId,
  }) async {
    final baseDatos = await _appDatabase.database;
    const filtro = 'perfil_id = ? AND modulo_id = ?';
    final argumentos = [perfilId, moduloId];

    final resumen = await baseDatos.query(
      _tablaModulo,
      where: filtro,
      whereArgs: argumentos,
      limit: 1,
    );

    if (resumen.isEmpty) {
      return ProgresoModulo.vacio(moduloId);
    }

    final lecturas = await baseDatos.query(
      _tablaLectura,
      where: filtro,
      whereArgs: argumentos,
      orderBy: 'recurso',
    );
    final actividades = await baseDatos.query(
      _tablaActividad,
      where: filtro,
      whereArgs: argumentos,
      orderBy: 'actividad_id',
    );
    final fecha = resumen.first['ultima_actualizacion'] as String?;

    return ProgresoModulo(
      moduloId: moduloId,
      porcentaje: resumen.first['porcentaje'] as int,
      ultimaActualizacion: fecha == null ? null : DateTime.parse(fecha),
      lecturas: lecturas.map(ProgresoLectura.fromMap).toList(),
      actividades: actividades.map(ProgresoActividad.fromMap).toList(),
    );
  }

  /// Módulo en el que el estudiante avanzó por última vez (HU08), o null si
  /// todavía no ha empezado ninguno.
  Future<String?> obtenerUltimoModuloId(String perfilId) async {
    final baseDatos = await _appDatabase.database;
    final filas = await baseDatos.query(
      _tablaModulo,
      columns: ['modulo_id'],
      where: 'perfil_id = ? AND ultima_actualizacion IS NOT NULL',
      whereArgs: [perfilId],
      orderBy: 'ultima_actualizacion DESC',
      limit: 1,
    );

    return filas.isEmpty ? null : filas.first['modulo_id'] as String;
  }

  /// Todo lo que falta enviar al servidor (HU10, criterio 2).
  Future<ProgresoPendiente> obtenerPendientes(String perfilId) async {
    final baseDatos = await _appDatabase.database;

    Future<List<Map<String, Object?>>> pendientesDe(String tabla) {
      return baseDatos.query(
        tabla,
        where: 'perfil_id = ? AND sincronizado = 0',
        whereArgs: [perfilId],
      );
    }

    return ProgresoPendiente(
      perfilId: perfilId,
      modulos: await pendientesDe(_tablaModulo),
      lecturas: await pendientesDe(_tablaLectura),
      actividades: await pendientesDe(_tablaActividad),
    );
  }

  /// Marca como enviados los registros de [enviados]. Se llama solo cuando
  /// el servidor confirmó el envío.
  ///
  /// Si el estudiante siguió jugando o leyendo mientras se enviaba, ese
  /// registro ya cambió (otra `ultima_actualizacion`) y queda pendiente para
  /// el próximo envío: así ningún avance se pierde. Devuelve cuántos
  /// registros se marcaron.
  ///
  /// En la misma transacción guarda la fecha de esta sincronización (HU11):
  /// o queda todo registrado, o nada.
  Future<int> marcarSincronizados(ProgresoPendiente enviados) async {
    final baseDatos = await _appDatabase.database;
    var marcados = 0;

    await baseDatos.transaction((txn) async {
      await txn.insert(
        _tablaEstado,
        {
          'perfil_id': enviados.perfilId,
          'ultima_sincronizacion': _ahora().toIso8601String(),
          'registros_enviados': enviados.lecturas.length +
              enviados.actividades.length +
              enviados.modulos.length,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final (tabla, filas) in [
        (_tablaModulo, enviados.modulos),
        (_tablaLectura, enviados.lecturas),
        (_tablaActividad, enviados.actividades),
      ]) {
        for (final fila in filas) {
          marcados += await txn.update(
            tabla,
            {'sincronizado': 1},
            where: 'id = ? AND ultima_actualizacion IS ?',
            whereArgs: [fila['id'], fila['ultima_actualizacion']],
          );
        }
      }
    });

    return marcados;
  }

  /// Fecha de la última sincronización correcta del perfil (HU11), o null si
  /// nunca se ha enviado nada.
  Future<DateTime?> obtenerUltimaSincronizacion(String perfilId) async {
    final baseDatos = await _appDatabase.database;
    final filas = await baseDatos.query(
      _tablaEstado,
      columns: ['ultima_sincronizacion'],
      where: 'perfil_id = ?',
      whereArgs: [perfilId],
      limit: 1,
    );

    return filas.isEmpty
        ? null
        : DateTime.parse(filas.first['ultima_sincronizacion'] as String);
  }

  /// Recalcula el resumen del módulo en `progreso_modulo`.
  ///
  /// Por ahora el porcentaje es el avance de lectura (promedio de los
  /// documentos). Cuando el manifest traiga la lista de actividades (HU07),
  /// el porcentaje podrá incluir las actividades completadas.
  Future<void> _actualizarResumen(
    Transaction txn,
    String perfilId,
    String moduloId,
    String fecha,
  ) async {
    final lecturas = await txn.query(
      _tablaLectura,
      columns: ['pagina_maxima', 'total_paginas'],
      where: 'perfil_id = ? AND modulo_id = ?',
      whereArgs: [perfilId, moduloId],
    );

    var porcentaje = 0;

    if (lecturas.isNotEmpty) {
      final suma = lecturas.fold<double>(
        0,
        (total, fila) =>
            total +
            (fila['pagina_maxima'] as int) / (fila['total_paginas'] as int),
      );
      porcentaje = min(max((suma / lecturas.length * 100).round(), 0), 100);
    }

    final datos = {
      'porcentaje': porcentaje,
      'ultima_actualizacion': fecha,
      'sincronizado': 0,
    };

    final actualizadas = await txn.update(
      _tablaModulo,
      datos,
      where: 'perfil_id = ? AND modulo_id = ?',
      whereArgs: [perfilId, moduloId],
    );

    if (actualizadas == 0) {
      await txn.insert(_tablaModulo, {
        'id': _uuid.v4(),
        'perfil_id': perfilId,
        'modulo_id': moduloId,
        ...datos,
      });
    }
  }
}
