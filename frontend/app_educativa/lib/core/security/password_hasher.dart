import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  PasswordHasher._();

  static const int _iteraciones = 10000;
  static const int _bytesSal = 16;
  static const int _valoresPorByte = 256;

  static String generarSal() {
    final random = Random.secure();
    final bytes = List<int>.generate(
      _bytesSal,
      (_) => random.nextInt(_valoresPorByte),
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

    for (var iteracion = 1; iteracion < _iteraciones; iteracion++) {
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

    return _sonIgualesEnTiempoConstante(hashCalculado, hashEsperado);
  }

  static bool _sonIgualesEnTiempoConstante(String primero, String segundo) {
    if (primero.length != segundo.length) {
      return false;
    }

    var diferencia = 0;
    for (var indice = 0; indice < primero.length; indice++) {
      diferencia |= primero.codeUnitAt(indice) ^ segundo.codeUnitAt(indice);
    }

    return diferencia == 0;
  }
}
