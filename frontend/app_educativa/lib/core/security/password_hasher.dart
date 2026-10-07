import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  PasswordHasher._();

  static const int _iteraciones = 10000;

  static String generarSal() {
    final random = Random.secure();
    final bytes = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    );

    return base64Url.encode(bytes);
  }

  static String hashear(
    String password,
    String sal,
  ) {
    var digest = sha256.convert(
      utf8.encode('$sal:$password'),
    );

    for (var i = 1; i < _iteraciones; i++) {
      digest = sha256.convert(digest.bytes);
    }

    return digest.toString();
  }

  static bool verificar(
    String password,
    String sal,
    String hashEsperado,
  ) {
    final hashCalculado = hashear(password, sal);

    if (hashCalculado.length != hashEsperado.length) {
      return false;
    }

    var diferencia = 0;
    for (var i = 0; i < hashCalculado.length; i++) {
      diferencia |=
          hashCalculado.codeUnitAt(i) ^ hashEsperado.codeUnitAt(i);
    }

    return diferencia == 0;
  }
}
