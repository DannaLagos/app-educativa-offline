import 'package:app_educativa/core/network/servidor_exception.dart';
import 'package:app_educativa/features/admin/data/catalogo_admin.dart';
import 'package:app_educativa/features/admin/presentation/screens/formulario_modulo_screen.dart';
import 'package:app_educativa/features/admin/presentation/screens/gestion_contenidos_screen.dart';
import 'package:app_educativa/features/modulos/domain/modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/datos_prueba.dart';

/// Catálogo en memoria, como si fuera Firestore.
class CatalogoFalso implements CatalogoAdmin {
  final Map<String, Modulo> modulos;
  bool debeFallar = false;

  CatalogoFalso(List<Modulo> iniciales)
      : modulos = {for (final m in iniciales) m.id: m};

  void _revisar() {
    if (debeFallar) {
      throw const ServidorException('No fue posible guardar los cambios.');
    }
  }

  @override
  Future<List<Modulo>> obtenerModulos() async => modulos.values.toList();

  @override
  Future<void> registrar(Modulo modulo) async {
    _revisar();
    if (modulos.containsKey(modulo.id)) {
      throw ModuloYaExisteException(modulo.id);
    }
    modulos[modulo.id] = modulo;
  }

  @override
  Future<void> actualizar(Modulo modulo) async {
    _revisar();
    modulos[modulo.id] = modulo;
  }

  @override
  Future<void> cambiarHabilitado(String moduloId, bool habilitado) async {
    _revisar();
    modulos[moduloId] = Modulo.desdeCatalogo({
      ...modulos[moduloId]!.toCatalogo(),
      'habilitado': habilitado,
    });
  }
}

void main() {
  late CatalogoFalso catalogo;

  setUp(() {
    catalogo = CatalogoFalso([
      moduloDePrueba(id: 'cs-grado-1', nombre: 'Ciencias Sociales'),
      moduloDePrueba(
        id: 'lg-grado-3-01',
        nombre: 'Lenguaje',
        estaHabilitado: false,
      ),
    ]);
  });

  Future<void> abrir(WidgetTester tester) async {
    // Pantalla alta, para que el formulario dibuje todos los campos.
    tester.view.physicalSize = const Size(1200, 4800);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(home: GestionContenidosScreen(catalogo: catalogo)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('criterio 1: muestra todos los módulos registrados', (
    tester,
  ) async {
    await abrir(tester);

    expect(find.text('Ciencias Sociales'), findsOneWidget);
    expect(find.text('Lenguaje'), findsOneWidget);
    expect(find.text('Habilitado'), findsOneWidget);
    expect(find.text('Deshabilitado'), findsOneWidget);
  });

  testWidgets('criterio 3: el interruptor deshabilita el módulo', (
    tester,
  ) async {
    await abrir(tester);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(catalogo.modulos['cs-grado-1']!.estaHabilitado, isFalse);
    expect(find.text('Habilitado'), findsNothing);
    expect(find.text('Deshabilitado'), findsNWidgets(2));
  });

  testWidgets('si no se puede guardar el estado, avisa y no lo cambia', (
    tester,
  ) async {
    await abrir(tester);
    catalogo.debeFallar = true;

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(catalogo.modulos['cs-grado-1']!.estaHabilitado, isTrue);
    expect(find.text('No fue posible guardar los cambios.'), findsOneWidget);
    expect(find.text('Habilitado'), findsOneWidget);
  });

  testWidgets('criterio 2: edita el nombre de un módulo y lo guarda', (
    tester,
  ) async {
    await abrir(tester);

    await tester.tap(find.text('Ciencias Sociales'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Sociales 1',
    );
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(catalogo.modulos['cs-grado-1']!.nombre, 'Sociales 1');
    expect(find.text('Sociales 1'), findsOneWidget);
  });

  testWidgets('criterio 2: registra un módulo nuevo, deshabilitado', (
    tester,
  ) async {
    await abrir(tester);

    await tester.tap(find.text('Nuevo módulo'));
    await tester.pumpAndSettle();

    Future<void> escribir(String campo, String texto) {
      return tester.enterText(find.widgetWithText(TextFormField, campo), texto);
    }

    await escribir('Identificador', 'mt-grado-2');
    await escribir('Nombre', 'Matemáticas');
    await escribir('Área', 'Matemáticas');
    await escribir('Grado', '2');
    await escribir('Descripción', 'Números y figuras');
    await escribir('Contenidos (uno por línea)', 'Sumas\n\nRestas');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final nuevo = catalogo.modulos['mt-grado-2']!;
    expect(nuevo.grado, 2);
    expect(nuevo.version, 1);
    expect(nuevo.estaHabilitado, isFalse);
    expect(nuevo.contenidos, ['Sumas', 'Restas']);
    expect(find.text('Matemáticas'), findsOneWidget);
  });

  group('validaciones del formulario', () {
    test('el identificador solo acepta minúsculas, números y guiones', () {
      expect(validarIdModulo('mt-grado-2'), isNull);
      expect(validarIdModulo(''), isNotNull);
      expect(validarIdModulo('Mt Grado'), isNotNull);
      expect(validarIdModulo('mt/grado'), isNotNull);
      expect(validarIdModulo('-mt'), isNotNull);
    });

    test('no deja repetir un identificador', () {
      expect(
        validarIdModulo('cs-grado-1', idsExistentes: {'cs-grado-1'}),
        isNotNull,
      );
    });

    test('grado y versión deben ser números en el rango', () {
      expect(validarEntero('3', minimo: 1, maximo: 11), isNull);
      expect(validarEntero('0', minimo: 1, maximo: 11), isNotNull);
      expect(validarEntero('12', minimo: 1, maximo: 11), isNotNull);
      expect(validarEntero('dos', minimo: 1), isNotNull);
    });
  });

  test('toCatalogo conserva los campos de catalogo.json', () {
    final modulo = moduloDePrueba(estaHabilitado: false, version: 3);

    final copia = Modulo.desdeCatalogo(modulo.toCatalogo());

    expect(copia.id, modulo.id);
    expect(copia.version, 3);
    expect(copia.estaHabilitado, isFalse);
    expect(copia.contenidos, modulo.contenidos);
  });
}
