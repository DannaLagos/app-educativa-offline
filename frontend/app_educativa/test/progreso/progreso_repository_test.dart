import 'package:app_educativa/core/database/app_database.dart';
import 'package:app_educativa/features/perfil/domain/perfil_estudiante.dart';
import 'package:app_educativa/features/progreso/data/progreso_local_datasource.dart';
import 'package:app_educativa/features/progreso/data/progreso_repository.dart';
import 'package:app_educativa/features/progreso/domain/resultado_actividad.dart';
import 'package:app_educativa/features/progreso/presentation/progreso_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/datos_prueba.dart';

void main() {
  late AppDatabase base;
  late ProgresoLocalDataSource local;
  String? perfilId;

  ProgresoRepository crearRepositorio() {
    return ProgresoRepository(
      local: local,
      obtenerPerfil: () async {
        final id = perfilId;
        return id == null ? null : PerfilEstudiante(id: id, nombre: 'Ana');
      },
    );
  }

  setUp(() {
    base = crearBaseEnMemoria();
    local = ProgresoLocalDataSource(appDatabase: base);
    perfilId = 'perfil-1';
  });

  tearDown(() => cerrarBase(base));

  group('ProgresoRepository', () {
    test('asocia el progreso al perfil del estudiante', () async {
      final repositorio = crearRepositorio();

      await repositorio.guardarPaginaLeida(
        moduloId: 'lg-grado-3-01',
        recurso: 'LG_Grado03_Periodo1.pdf',
        pagina: 3,
        totalPaginas: 30,
      );

      final guardado = await local.obtenerProgresoModulo(
        perfilId: 'perfil-1',
        moduloId: 'lg-grado-3-01',
      );
      expect(guardado.lecturaDe('LG_Grado03_Periodo1.pdf')!.ultimaPagina, 3);
    });

    test('sin perfil no guarda nada y avisa con SinPerfilException',
        () async {
      perfilId = null;
      final repositorio = crearRepositorio();

      expect(
        repositorio.registrarResultadoActividad(
          const ResultadoActividad(
            moduloId: 'cs-grado-1',
            actividadId: 'quiz-1',
            completada: true,
            puntaje: 100,
          ),
        ),
        throwsA(isA<SinPerfilException>()),
      );
      expect(
        (await repositorio.obtenerProgresoModulo('cs-grado-1')).estaIniciado,
        isFalse,
      );
    });

    test('reconoce un perfil creado después de abrir la app', () async {
      perfilId = null;
      final repositorio = crearRepositorio();
      await repositorio.obtenerProgresoModulo('cs-grado-1');

      perfilId = 'perfil-nuevo';
      await repositorio.guardarPaginaLeida(
        moduloId: 'cs-grado-1',
        recurso: 'a.pdf',
        pagina: 1,
        totalPaginas: 4,
      );

      expect(
        (await repositorio.obtenerProgresoModulo('cs-grado-1')).porcentaje,
        25,
      );
    });
  });

  group('ProgresoController', () {
    test('HU06 CA2: guarda sin internet (solo usa el dispositivo)', () async {
      // Offline first: el repositorio no tiene servidor y aun así guarda.
      final controller = ProgresoController(repositorio: crearRepositorio());

      final guardado = await controller.guardarPagina(
        moduloId: 'cs-grado-1',
        recurso: 'fichas.pdf',
        pagina: 6,
        totalPaginas: 12,
      );

      expect(guardado, isTrue);
      expect(controller.progresoDe('cs-grado-1').porcentaje, 50);
      expect(
        await controller.paginaParaContinuar('cs-grado-1', 'fichas.pdf'),
        6,
      );
    });

    test('un documento nunca abierto empieza desde el inicio', () async {
      final controller = ProgresoController(repositorio: crearRepositorio());

      expect(
        await controller.paginaParaContinuar('cs-grado-1', 'nuevo.pdf'),
        isNull,
      );
    });

    test('si no se puede guardar, devuelve false sin lanzar errores',
        () async {
      perfilId = null;
      final controller = ProgresoController(repositorio: crearRepositorio());

      final guardado = await controller.registrarResultado(
        const ResultadoActividad(
          moduloId: 'cs-grado-1',
          actividadId: 'quiz-1',
          completada: true,
          puntaje: 50,
        ),
      );

      expect(guardado, isFalse);
    });

    test('avisa a las pantallas cuando cambia el progreso', () async {
      final controller = ProgresoController(repositorio: crearRepositorio());
      var avisos = 0;
      controller.addListener(() => avisos++);

      await controller.registrarResultado(
        const ResultadoActividad(
          moduloId: 'cs-grado-1',
          actividadId: 'quiz-1',
          completada: true,
          puntaje: 50,
        ),
      );

      expect(avisos, greaterThan(0));
      expect(controller.progresoDe('cs-grado-1').actividadesCompletadas, 1);
    });
  });
}
