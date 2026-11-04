import 'package:app_educativa/core/database/app_database.dart';
import 'package:app_educativa/core/network/conectividad_service.dart';
import 'package:app_educativa/core/network/servidor_exception.dart';
import 'package:app_educativa/features/perfil/domain/perfil_estudiante.dart';
import 'package:app_educativa/features/progreso/data/progreso_local_datasource.dart';
import 'package:app_educativa/features/progreso/data/progreso_remote_datasource.dart';
import 'package:app_educativa/features/progreso/data/progreso_repository.dart';
import 'package:app_educativa/features/progreso/domain/progreso_pendiente.dart';
import 'package:app_educativa/features/progreso/domain/resultado_actividad.dart';
import 'package:app_educativa/features/progreso/domain/resultado_sincronizacion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/datos_prueba.dart';

class MockRemote extends Mock implements ProgresoRemoteDataSource {}

class MockConectividad extends Mock implements ConectividadService {}

const _perfil = PerfilEstudiante(id: 'perfil-1', nombre: 'Sofía');
const _modulo = 'cs-grado-1';

void main() {
  late AppDatabase base;
  late ProgresoLocalDataSource local;
  late MockRemote remote;
  late MockConectividad conectividad;
  late ProgresoRepository repositorio;
  var ahora = DateTime(2026, 10, 25, 10);

  setUpAll(() {
    registerFallbackValue(const ProgresoPendiente(perfilId: 'x'));
  });

  setUp(() {
    ahora = DateTime(2026, 10, 25, 10);
    base = crearBaseEnMemoria();
    local = ProgresoLocalDataSource(appDatabase: base, ahora: () => ahora);
    remote = MockRemote();
    conectividad = MockConectividad();
    repositorio = ProgresoRepository(
      local: local,
      remote: remote,
      conectividad: conectividad,
      obtenerPerfil: () async => _perfil,
    );

    when(() => conectividad.hayConexion()).thenAnswer((_) async => true);
    when(() => remote.enviar(any())).thenAnswer((_) async {});
  });

  tearDown(() => cerrarBase(base));

  Future<void> jugar(String actividadId, {int puntaje = 100}) {
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
    return local.guardarLectura(
      perfilId: _perfil.id,
      moduloId: _modulo,
      recurso: 'cartilla.pdf',
      pagina: pagina,
      totalPaginas: 20,
    );
  }

  test('offline first: guardar y leer nunca usan la red ni el servidor',
      () async {
    await repositorio.guardarPaginaLeida(
      moduloId: _modulo,
      recurso: 'cartilla.pdf',
      pagina: 5,
      totalPaginas: 20,
    );
    final progreso = await repositorio.obtenerProgresoModulo(_modulo);

    expect(progreso.lecturaDe('cartilla.pdf')!.ultimaPagina, 5);
    verifyNever(() => conectividad.hayConexion());
    verifyNever(() => remote.enviar(any()));
  });

  test('offline first: si el servidor falla, lo guardado se sigue leyendo',
      () async {
    when(() => remote.enviar(any()))
        .thenThrow(const ServidorException('sin respuesta'));
    await jugar('a1', puntaje: 90);

    await repositorio.sincronizar();

    final progreso = await repositorio.obtenerProgresoModulo(_modulo);
    expect(progreso.actividadDe('a1')!.puntaje, 90);
    expect(progreso.actividadDe('a1')!.sincronizado, isFalse);
  });

  test('sin avances no hay nada por enviar', () async {
    expect(await repositorio.sincronizar(), isA<SinPendientes>());
    expect(await repositorio.contarPendientes(), 0);
    verifyNever(() => remote.enviar(any()));
  });

  test('cada avance guardado queda pendiente de envío', () async {
    await jugar('a1');
    await leer(4);

    final pendientes = await local.obtenerPendientes(_perfil.id);

    expect(pendientes.actividades, hasLength(1));
    expect(pendientes.lecturas, hasLength(1));
    expect(pendientes.modulos, hasLength(1));
    expect(await repositorio.contarPendientes(), 2);
  });

  test('CA2: sin conexión conserva los datos hasta poder enviarlos', () async {
    when(() => conectividad.hayConexion()).thenAnswer((_) async => false);
    await jugar('a1');

    final resultado = await repositorio.sincronizar();

    expect(resultado, isA<SinConexion>());
    expect((resultado as SinConexion).pendientes, 1);
    verifyNever(() => remote.enviar(any()));
    expect(await repositorio.contarPendientes(), 1);
  });

  test('CA3: si el envío falla, nada se pierde y sigue pendiente', () async {
    when(() => remote.enviar(any()))
        .thenThrow(const ServidorException('sin respuesta'));
    await jugar('a1', puntaje: 80);
    await leer(7);

    final resultado = await repositorio.sincronizar();

    expect(resultado, isA<FalloSincronizacion>());
    expect(await repositorio.contarPendientes(), 2);

    final progreso = await local.obtenerProgresoModulo(
      perfilId: _perfil.id,
      moduloId: _modulo,
    );
    expect(progreso.actividadDe('a1')!.puntaje, 80);
    expect(progreso.lecturaDe('cartilla.pdf')!.ultimaPagina, 7);
  });

  test('CA4: al reintentar con conexión se envía todo lo pendiente', () async {
    when(() => conectividad.hayConexion()).thenAnswer((_) async => false);
    await jugar('a1');
    await jugar('a2');
    expect(await repositorio.sincronizar(), isA<SinConexion>());

    when(() => conectividad.hayConexion()).thenAnswer((_) async => true);
    final resultado = await repositorio.sincronizar();

    expect(resultado, isA<Enviado>());
    final enviado = verify(() => remote.enviar(captureAny())).captured.single
        as ProgresoPendiente;
    expect(enviado.perfilId, _perfil.id);
    expect(enviado.nombreEstudiante, 'Sofía');
    expect(
      enviado.actividades.map((fila) => fila['actividad_id']),
      unorderedEquals(['a1', 'a2']),
    );
    expect(await repositorio.contarPendientes(), 0);
  });

  test('un avance nuevo después de enviar vuelve a quedar pendiente', () async {
    await jugar('a1');
    await repositorio.sincronizar();
    expect(await repositorio.contarPendientes(), 0);

    ahora = ahora.add(const Duration(minutes: 1));
    await jugar('a1', puntaje: 50);

    expect(await repositorio.contarPendientes(), 1);
  });

  test('lo que cambia mientras se envía no se marca como enviado', () async {
    await jugar('a1', puntaje: 60);

    when(() => remote.enviar(any())).thenAnswer((_) async {
      // El niño vuelve a jugar mientras el envío está en camino.
      ahora = ahora.add(const Duration(seconds: 5));
      await jugar('a1', puntaje: 100);
    });

    expect(await repositorio.sincronizar(), isA<Enviado>());

    final pendientes = await local.obtenerPendientes(_perfil.id);
    expect(pendientes.actividades.single['puntaje'], 100);
  });

  test('sin perfil no intenta enviar', () async {
    final sinPerfil = ProgresoRepository(
      local: local,
      remote: remote,
      conectividad: conectividad,
      obtenerPerfil: () async => null,
    );

    expect(await sinPerfil.sincronizar(), isA<SinPendientes>());
    expect(await sinPerfil.contarPendientes(), 0);
  });

  group('documentosDeProgreso', () {
    test('cada registro tiene una ruta fija (reintentar no duplica)', () async {
      await jugar('a1');
      await leer(3);

      final pendientes =
          (await local.obtenerPendientes(_perfil.id)).conNombre('Sofía');
      final documentos = documentosDeProgreso(pendientes);
      final rutas = documentos.map((documento) => documento.ruta);

      expect(rutas, [
        'estudiantes/perfil-1',
        'estudiantes/perfil-1/modulos/cs-grado-1',
        'estudiantes/perfil-1/lecturas/cs-grado-1__cartilla.pdf',
        'estudiantes/perfil-1/actividades/cs-grado-1__a1',
      ]);
      expect(documentos.first.datos['nombre'], 'Sofía');
      expect(documentosDeProgreso(pendientes).map((d) => d.ruta), rutas);

      for (final documento in documentos.skip(1)) {
        expect(documento.datos.containsKey('sincronizado'), isFalse);
        expect(documento.datos.containsKey('id'), isFalse);
        expect(documento.datos['perfil_id'], 'perfil-1');
      }
    });

    test('quita las barras de los identificadores', () {
      expect(idSeguro('a/b'), 'a_b');
    });
  });
}
