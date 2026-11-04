import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_educativa/core/security/password_hasher.dart';
import 'package:app_educativa/features/admin/data/autenticacion_admin.dart';
import 'package:app_educativa/features/admin/domain/acceso_admin_exception.dart';
import 'package:app_educativa/features/admin/domain/sesion_admin.dart';
import 'package:app_educativa/features/admin/domain/superadministrador.dart';
import 'package:app_educativa/features/admin/presentation/screens/login_admin_screen.dart';

/// Acepta solo admin@aprendo.co / Clave123*.
class AutenticacionFalsa implements AutenticacionAdmin {
  int cierres = 0;

  @override
  Future<Superadministrador> iniciarSesion(
    String correo,
    String password,
  ) async {
    if (correo == 'admin@aprendo.co' && password == 'Clave123*') {
      return const Superadministrador(id: 'uid-1', usuario: 'Valentina');
    }

    throw const AccesoAdminException(AccesoAdminException.datosInvalidos);
  }

  @override
  Future<void> cerrarSesion() async => cierres++;
}

void main() {
  group('PasswordHasher', () {
    test('acepta la contraseña correcta', () {
      final sal = PasswordHasher.generarSal();
      final hash = PasswordHasher.hashear('Clave123*', sal);

      expect(PasswordHasher.verificar('Clave123*', sal, hash), isTrue);
    });

    test('rechaza una contraseña incorrecta', () {
      final sal = PasswordHasher.generarSal();
      final hash = PasswordHasher.hashear('Clave123*', sal);

      expect(PasswordHasher.verificar('otra', sal, hash), isFalse);
    });

    test('no guarda la contraseña en texto plano', () {
      final sal = PasswordHasher.generarSal();
      final hash = PasswordHasher.hashear('Clave123*', sal);

      expect(hash.contains('Clave123*'), isFalse);
      expect(PasswordHasher.generarSal(), isNot(sal));
    });
  });

  test('cerrar sesión exige autenticarse de nuevo', () {
    final sesion = SesionAdmin.instance;

    sesion.iniciar(
      const Superadministrador(id: '1', usuario: 'admin'),
    );
    expect(sesion.estaActiva, isTrue);

    sesion.cerrar();
    expect(sesion.estaActiva, isFalse);
    expect(sesion.actual, isNull);
  });

  group('HU12: inicio de sesión del superadministrador', () {
    late AutenticacionFalsa autenticacion;

    setUp(() {
      autenticacion = AutenticacionFalsa();
      SesionAdmin.instance.cerrar();
    });

    Future<void> abrirLogin(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginAdminScreen(
            autenticacion: autenticacion,
            construirPanel: (_) => const Scaffold(body: Text('Panel')),
          ),
        ),
      );
    }

    Future<void> ingresar(
      WidgetTester tester,
      String correo,
      String password,
    ) async {
      await tester.enterText(find.byType(TextField).at(0), correo);
      await tester.enterText(find.byType(TextField).at(1), password);
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();
    }

    testWidgets('pide correo y contraseña antes de validar', (tester) async {
      await abrirLogin(tester);

      await tester.tap(find.text('Ingresar'));
      await tester.pump();

      expect(find.text('Ingresa tu correo y contraseña.'), findsOneWidget);
    });

    testWidgets('criterio 1: con datos válidos abre el panel', (tester) async {
      await abrirLogin(tester);

      await ingresar(tester, 'admin@aprendo.co', 'Clave123*');

      expect(find.text('Panel'), findsOneWidget);
      expect(SesionAdmin.instance.actual?.usuario, 'Valentina');
    });

    testWidgets('criterio 2: con datos incorrectos avisa y no entra', (
      tester,
    ) async {
      await abrirLogin(tester);

      await ingresar(tester, 'admin@aprendo.co', 'otra');

      expect(find.text('Los datos de acceso no son válidos.'), findsOneWidget);
      expect(find.text('Panel'), findsNothing);
      expect(SesionAdmin.instance.estaActiva, isFalse);
    });
  });

  group('mensajeDeAcceso', () {
    test('no dice si falló el correo o la contraseña', () {
      for (final codigo in [
        'invalid-credential',
        'wrong-password',
        'user-not-found',
        'invalid-email',
        'permission-denied',
      ]) {
        expect(mensajeDeAcceso(codigo), AccesoAdminException.datosInvalidos);
      }
    });

    test('avisa cuando falta internet o hay demasiados intentos', () {
      expect(
        mensajeDeAcceso('network-request-failed'),
        AccesoAdminException.sinConexion,
      );
      expect(
        mensajeDeAcceso('too-many-requests'),
        AccesoAdminException.demasiadosIntentos,
      );
    });
  });
}
