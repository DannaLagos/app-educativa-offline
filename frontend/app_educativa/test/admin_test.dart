import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_educativa/core/security/password_hasher.dart';
import 'package:app_educativa/features/admin/domain/sesion_admin.dart';
import 'package:app_educativa/features/admin/domain/superadministrador.dart';
import 'package:app_educativa/features/admin/presentation/screens/login_admin_screen.dart';

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

  testWidgets('pide usuario y contraseña antes de validar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginAdminScreen(),
      ),
    );

    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(
      find.text('Ingresa tu usuario y contraseña.'),
      findsOneWidget,
    );
  });
}
