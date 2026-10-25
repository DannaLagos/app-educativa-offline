import 'dart:math';

import 'actividad.dart';

enum DireccionSopa { horizontal, vertical }

/// Dónde quedó escondida una palabra.
class UbicacionPalabra {
  final String palabra;
  final int fila;
  final int columna;
  final DireccionSopa direccion;

  const UbicacionPalabra({
    required this.palabra,
    required this.fila,
    required this.columna,
    required this.direccion,
  });

  /// Celdas que ocupa, en orden: (fila, columna).
  List<(int, int)> get celdas => [
        for (var i = 0; i < palabra.length; i++)
          direccion == DireccionSopa.horizontal
              ? (fila, columna + i)
              : (fila + i, columna),
      ];

  (int, int) get inicio => celdas.first;

  (int, int) get fin => celdas.last;
}

/// Cuadrícula de letras de una sopa de letras.
class CuadriculaSopa {
  /// Letras de relleno (las más comunes del español, para que no salgan
  /// palabras raras por casualidad con letras poco usadas).
  static const String _relleno = 'AEIOUABCDEFGLMNOPRSTU';
  static const int _intentosPorPalabra = 300;
  static const int _intentosCompletos = 30;

  final int tamano;
  final List<List<String>> letras;
  final List<UbicacionPalabra> ubicaciones;

  const CuadriculaSopa._(this.tamano, this.letras, this.ubicaciones);

  String letra(int fila, int columna) => letras[fila][columna];

  /// Genera una cuadrícula con todas las [palabras]. Si no caben en
  /// [tamano], agranda la cuadrícula.
  factory CuadriculaSopa.generar(
    List<String> palabras,
    int tamano,
    Random random,
  ) {
    final normalizadas = palabras.map(normalizarPalabra).toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (var lado = tamano; lado <= tamano + 4; lado++) {
      for (var intento = 0; intento < _intentosCompletos; intento++) {
        final resultado = _intentar(normalizadas, lado, random);

        if (resultado != null) {
          return resultado;
        }
      }
    }

    throw StateError('No se pudo armar la sopa de letras.');
  }

  static CuadriculaSopa? _intentar(
    List<String> palabras,
    int lado,
    Random random,
  ) {
    final celdas = List.generate(lado, (_) => List<String?>.filled(lado, null));
    final ubicaciones = <UbicacionPalabra>[];

    for (final palabra in palabras) {
      final ubicacion = _ubicar(palabra, celdas, lado, random);

      if (ubicacion == null) {
        return null;
      }

      for (final (indice, (fila, columna)) in ubicacion.celdas.indexed) {
        celdas[fila][columna] = palabra[indice];
      }
      ubicaciones.add(ubicacion);
    }

    final letras = [
      for (final fila in celdas)
        [
          for (final letra in fila)
            letra ?? _relleno[random.nextInt(_relleno.length)],
        ],
    ];

    return CuadriculaSopa._(lado, letras, ubicaciones);
  }

  static UbicacionPalabra? _ubicar(
    String palabra,
    List<List<String?>> celdas,
    int lado,
    Random random,
  ) {
    if (palabra.length > lado) {
      return null;
    }

    for (var intento = 0; intento < _intentosPorPalabra; intento++) {
      final direccion = random.nextBool()
          ? DireccionSopa.horizontal
          : DireccionSopa.vertical;
      final maximo = lado - palabra.length;
      final fila = direccion == DireccionSopa.vertical
          ? random.nextInt(maximo + 1)
          : random.nextInt(lado);
      final columna = direccion == DireccionSopa.horizontal
          ? random.nextInt(maximo + 1)
          : random.nextInt(lado);
      final ubicacion = UbicacionPalabra(
        palabra: palabra,
        fila: fila,
        columna: columna,
        direccion: direccion,
      );

      final cabe = ubicacion.celdas.indexed.every((entrada) {
        final (indice, (f, c)) = entrada;
        final actual = celdas[f][c];

        return actual == null || actual == palabra[indice];
      });

      if (cabe) {
        return ubicacion;
      }
    }

    return null;
  }

  /// La palabra que va de [a] a [b] (en cualquier sentido), o null si no
  /// hay ninguna escondida ahí.
  UbicacionPalabra? buscar((int, int) a, (int, int) b) {
    for (final ubicacion in ubicaciones) {
      if ((ubicacion.inicio == a && ubicacion.fin == b) ||
          (ubicacion.inicio == b && ubicacion.fin == a)) {
        return ubicacion;
      }
    }

    return null;
  }
}
