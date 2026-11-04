import 'package:app_educativa/core/network/servidor_exception.dart';
import 'package:app_educativa/features/admin/data/uso_app_datasource.dart';
import 'package:app_educativa/features/admin/domain/resumen_uso.dart';
import 'package:app_educativa/features/admin/presentation/screens/uso_app_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class UsoFalso implements UsoAppDataSource {
  DatosUso datos;
  bool debeFallar = false;

  UsoFalso(this.datos);

  @override
  Future<DatosUso> obtenerDatos() async {
    if (debeFallar) {
      throw const ServidorException('No fue posible consultar la información de uso.');
    }
    return datos;
  }
}

final _ana = DateTime.utc(2026, 11, 2, 15);
final _luis = DateTime.utc(2026, 11, 3, 9);

/// Ana y Luis usan Ciencias Sociales; solo Ana usa Lenguaje.
DatosUso _datosDePrueba() {
  return DatosUso(
    estudiantes: [
      {'perfil_id': 'ana', 'nombre': 'Ana', 'sincronizado_en': _ana},
      {'perfil_id': 'luis', 'nombre': 'Luis', 'sincronizado_en': _luis},
    ],
    modulos: [
      {'perfil_id': 'ana', 'modulo_id': 'cs-grado-1', 'porcentaje': 80},
      {'perfil_id': 'luis', 'modulo_id': 'cs-grado-1', 'porcentaje': 40},
      {'perfil_id': 'ana', 'modulo_id': 'lg-grado-3-01', 'porcentaje': 30},
    ],
    lecturas: [
      {'perfil_id': 'ana', 'modulo_id': 'cs-grado-1', 'pagina_maxima': 8},
      {'perfil_id': 'luis', 'modulo_id': 'cs-grado-1', 'pagina_maxima': 4},
    ],
    actividades: [
      {
        'perfil_id': 'ana',
        'modulo_id': 'cs-grado-1',
        'completada': 1,
        'intentos': 2,
      },
      {
        'perfil_id': 'luis',
        'modulo_id': 'cs-grado-1',
        'completada': 0,
        'intentos': 3,
      },
      {
        'perfil_id': 'ana',
        'modulo_id': 'lg-grado-3-01',
        'completada': 1,
        'intentos': 1,
      },
    ],
    nombresModulos: {'cs-grado-1': 'Ciencias Sociales'},
  );
}

void main() {
  group('ResumenUso.calcular (criterio 2)', () {
    late ResumenUso resumen;

    setUp(() => resumen = ResumenUso.calcular(_datosDePrueba()));

    test('cuenta estudiantes, actividades, intentos y páginas', () {
      expect(resumen.totalEstudiantes, 2);
      expect(resumen.actividadesCompletadas, 2);
      expect(resumen.intentos, 6);
      expect(resumen.paginasLeidas, 12);
      expect(resumen.avancePromedio, 50); // (80 + 40 + 30) / 3
    });

    test('resume cada módulo, del más usado al menos usado', () {
      final [sociales, lenguaje] = resumen.modulos;

      expect(sociales.nombre, 'Ciencias Sociales');
      expect(sociales.estudiantes, 2);
      expect(sociales.avancePromedio, 60);
      expect(sociales.actividadesCompletadas, 1);
      expect(sociales.intentos, 5);

      // Sin nombre en el catálogo, se muestra el id.
      expect(lenguaje.nombre, 'lg-grado-3-01');
      expect(lenguaje.estudiantes, 1);
    });

    test('resume cada estudiante, el que sincronizó más reciente primero', () {
      final [luis, ana] = resumen.estudiantes;

      expect(luis.nombre, 'Luis');
      expect(luis.ultimaSincronizacion, _luis);
      expect(ana.modulosUsados, 2);
      expect(ana.actividadesCompletadas, 2);
      expect(ana.avancePromedio, 55);
    });

    test('sin datos sincronizados queda vacío', () {
      final vacio = ResumenUso.calcular(const DatosUso());

      expect(vacio.estaVacio, isTrue);
      expect(vacio.avancePromedio, 0);
    });
  });

  group('UsoAppScreen', () {
    // Pantalla alta, para que la lista dibuje todas las tarjetas.
    Future<void> abrir(WidgetTester tester, UsoFalso fuente) async {
      tester.view.physicalSize = const Size(1200, 4800);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(home: UsoAppScreen(datos: fuente)));
      await tester.pumpAndSettle();
    }

    testWidgets('criterio 1 y 2: muestra la información sincronizada', (
      tester,
    ) async {
      await abrir(tester, UsoFalso(_datosDePrueba()));

      expect(find.text('Módulos utilizados'), findsOneWidget);
      expect(find.text('Ciencias Sociales'), findsOneWidget);
      expect(find.text('Luis'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
    });

    testWidgets('criterio 3: lo nuevo aparece al actualizar tras sincronizar', (
      tester,
    ) async {
      final fuente = UsoFalso(const DatosUso());

      await abrir(tester, fuente);

      expect(
        find.text('Aún no hay datos sincronizados de los estudiantes.'),
        findsOneWidget,
      );

      // Un dispositivo sincronizó sus pendientes.
      fuente.datos = _datosDePrueba();
      await tester.tap(find.byTooltip('Actualizar'));
      await tester.pumpAndSettle();

      expect(find.text('Ciencias Sociales'), findsOneWidget);
    });

    testWidgets('si no puede consultar, avisa y deja reintentar', (
      tester,
    ) async {
      final fuente = UsoFalso(_datosDePrueba())..debeFallar = true;

      await abrir(tester, fuente);

      expect(
        find.text('No fue posible consultar la información de uso.'),
        findsOneWidget,
      );

      fuente.debeFallar = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Ciencias Sociales'), findsOneWidget);
    });
  });
}
