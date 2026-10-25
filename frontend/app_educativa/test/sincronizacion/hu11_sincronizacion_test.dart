import 'dart:async';

import 'package:app_educativa/core/database/app_database.dart';
import 'package:app_educativa/core/network/conectividad_service.dart';
import 'package:app_educativa/core/network/servidor_exception.dart';
import 'package:app_educativa/features/perfil/domain/perfil_estudiante.dart';
import 'package:app_educativa/features/progreso/data/progreso_local_datasource.dart';
import 'package:app_educativa/features/progreso/domain/progreso_pendiente.dart';
import 'package:app_educativa/features/progreso/domain/resultado_actividad.dart';
import 'package:app_educativa/features/sincronizacion/data/progreso_remote_datasource.dart';
import 'package:app_educativa/features/sincronizacion/data/sincronizacion_service.dart';
import 'package:app_educativa/features/sincronizacion/domain/resultado_sincronizacion.dart';
import 'package:app_educativa/features/sincronizacion/presentation/sincronizacion_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/datos_prueba.dart';

/// Servidor falso que guarda los documentos como Firestore con
/// `set(..., merge: true)`: un documento por ruta.
class ServidorFalso implements ProgresoRemoteDataSource {
  final Map<String, Map<String, Object?>> documentos = {};
  bool falla = false;
  int envios = 0;

  @override
  Future<void> enviar(ProgresoPendiente pendientes) async {
    envios++;
    if (falla) {
      throw const ServidorException('El servidor no respondió.');
    }

    for (final documento in documentosDeProgreso(pendientes, uid: 'uid-1')) {
      documentos[documento.ruta] = {
        ...?documentos[documento.ruta],
        ...documento.datos,
      };
    }
  }

  Iterable<String> rutasDe(String coleccion) =>
      documentos.keys.where((ruta) => ruta.contains('/$coleccion/'));
}

class ConectividadFalsa implements ConectividadService {
  final _cambios = StreamController<bool>.broadcast();
  bool hayRed;

  ConectividadFalsa({this.hayRed = true});

  void cambiar(bool valor) {
    hayRed = valor;
    _cambios.add(valor);
  }

  @override
  Future<bool> hayConexion() async => hayRed;

  @override
  Stream<bool> get cambios => _cambios.stream;

  Future<void> cerrar() => _cambios.close();
}

const _perfil = PerfilEstudiante(id: 'perfil-1', nombre: 'Sofía');
const _modulo = 'cs-grado-1';

void main() {
  late AppDatabase base;
  late ProgresoLocalDataSource local;
  late ServidorFalso servidor;
  late ConectividadFalsa conectividad;
  late SincronizacionService servicio;
  var ahora = DateTime(2026, 10, 25, 10);

  setUp(() {
    ahora = DateTime(2026, 10, 25, 10);
    base = crearBaseEnMemoria();
    local = ProgresoLocalDataSource(appDatabase: base, ahora: () => ahora);
    servidor = ServidorFalso();
    conectividad = ConectividadFalsa();
    servicio = SincronizacionService(
      local: local,
      remote: servidor,
      conectividad: conectividad,
      obtenerPerfil: () async => _perfil,
    );
  });

  tearDown(() async {
    await conectividad.cerrar();
    await cerrarBase(base);
  });

  Future<void> jugar(String actividadId, {int puntaje = 100}) {
    ahora = ahora.add(const Duration(minutes: 1));
    return local.registrarResultado(
      perfilId: _perfil.id,
      resultado: ResultadoActividad(
        moduloId: _modulo,
        actividadId: actividadId,
        completada: true,
        puntaje: puntaje,
      ),
    );
  }

  Future<void> leer(int pagina) {
    ahora = ahora.add(const Duration(minutes: 1));
    return local.guardarLectura(
      perfilId: _perfil.id,
      moduloId: _modulo,
      recurso: 'cartilla.pdf',
      pagina: pagina,
      totalPaginas: 20,
    );
  }

  Future<List<Object?>> columnaSincronizado(String tabla) async {
    final db = await base.database;
    final filas = await db.query(tabla, columns: ['sincronizado']);
    return filas.map((fila) => fila['sincronizado']).toList();
  }

  test('CA1: con datos pendientes, al recuperar la conexión intenta '
      'sincronizar', () async {
    conectividad.hayRed = false;
    final controller = SincronizacionController(
      servicio: servicio,
      conectividad: conectividad,
      esperaTrasCambio: Duration.zero,
    );
    addTearDown(controller.dispose);

    await jugar('a1');
    await controller.iniciar();
    expect(servidor.envios, 0, reason: 'sin red no se intenta');
    expect(controller.pendientes, 1);

    conectividad.cambiar(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(servidor.envios, 1);
    expect(servidor.rutasDe('actividades'), hasLength(1));
    expect(controller.pendientes, 0);
  });

  test('CA2: al terminar bien, todo queda registrado como sincronizado',
      () async {
    await jugar('a1', puntaje: 80);
    await leer(5);

    expect(await servicio.sincronizar(), isA<Enviado>());

    expect(await columnaSincronizado('progreso_actividad'), [1]);
    expect(await columnaSincronizado('progreso_lectura'), [1]);
    expect(await columnaSincronizado('progreso_modulo'), [1]);
    expect(await servicio.contarPendientes(), 0);

    // La fecha queda guardada en el teléfono.
    expect(await servicio.ultimaSincronizacion(), ahora);

    // Y las pantallas pueden mostrarlo por juego y por lectura.
    final progreso = await local.obtenerProgresoModulo(
      perfilId: _perfil.id,
      moduloId: _modulo,
    );
    expect(progreso.actividadDe('a1')!.sincronizado, isTrue);
    expect(progreso.lecturaDe('cartilla.pdf')!.sincronizado, isTrue);
  });

  test('CA3: sincronizar otra vez no genera registros duplicados', () async {
    await jugar('a1', puntaje: 60);
    await leer(3);
    await servicio.sincronizar();
    final documentosIniciales = servidor.documentos.length;

    // Sin cambios: no hay nada que enviar.
    expect(await servicio.sincronizar(), isA<SinPendientes>());

    // El niño repite el juego y sigue leyendo: se actualizan los mismos
    // documentos en lugar de crear otros.
    await jugar('a1', puntaje: 100);
    await leer(9);
    expect(await servicio.sincronizar(), isA<Enviado>());

    expect(servidor.documentos, hasLength(documentosIniciales));
    expect(servidor.rutasDe('actividades'), hasLength(1));
    expect(servidor.rutasDe('lecturas'), hasLength(1));
    expect(servidor.rutasDe('modulos'), hasLength(1));
    expect(
      servidor.documentos['estudiantes/perfil-1/actividades/cs-grado-1__a1']![
          'puntaje'],
      100,
    );
    expect(
      servidor.documentos['estudiantes/perfil-1/lecturas/'
          'cs-grado-1__cartilla.pdf']!['ultima_pagina'],
      9,
    );

    // En el teléfono tampoco se duplica nada.
    final db = await base.database;
    expect(await db.query('progreso_actividad'), hasLength(1));
    expect(await db.query('progreso_lectura'), hasLength(1));
    expect(await db.query('estado_sincronizacion'), hasLength(1));
  });

  test('CA3: reenviar lo mismo (por ejemplo, tras un corte) deja los mismos '
      'documentos', () async {
    await jugar('a1');
    final pendientes = await local.obtenerPendientes(_perfil.id);

    await servidor.enviar(pendientes);
    final despuesDelPrimero = Map.of(servidor.documentos);
    await servidor.enviar(pendientes);

    expect(servidor.documentos.keys, despuesDelPrimero.keys);
  });

  test('CA4: si no se completa, la información sigue guardada para un '
      'intento posterior', () async {
    servidor.falla = true;
    await jugar('a1', puntaje: 70);
    await leer(4);

    expect(await servicio.sincronizar(), isA<FalloSincronizacion>());

    expect(await columnaSincronizado('progreso_actividad'), [0]);
    expect(await columnaSincronizado('progreso_lectura'), [0]);
    expect(await servicio.contarPendientes(), 2);
    expect(await servicio.ultimaSincronizacion(), isNull);
    expect(servidor.documentos, isEmpty);

    // Intento posterior: ahora sí se envía todo lo que estaba guardado.
    servidor.falla = false;
    expect(await servicio.sincronizar(), isA<Enviado>());
    expect(
      servidor.documentos['estudiantes/perfil-1/actividades/cs-grado-1__a1']![
          'puntaje'],
      70,
    );
    expect(await servicio.contarPendientes(), 0);
  });

  test('cada documento lleva el uid del dueño para las reglas de Firestore',
      () async {
    await jugar('a1');
    await servicio.sincronizar();

    for (final datos in servidor.documentos.values) {
      expect(datos['uid'], 'uid-1');
    }
  });
}
