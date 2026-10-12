import 'package:flutter/material.dart';

/// Tema para estudiantes de primaria: colores de alto contraste (texto
/// blanco sobre fondos oscuros cumple WCAG AA), letra grande y botones
/// de al menos 56 px de alto.
class AppTheme {
  AppTheme._();

  static const Color azul = Color(0xFF0D47A1);
  static const Color verde = Color(0xFF1B5E20);
  static const Color rojo = Color(0xFFB71C1C);
  static const Color gris = Color(0xFF37474F);
  static const Color textoSecundario = Color(0xFF424242);

  static ThemeData get claro {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: azul,
      primary: azul,
      error: rojo,
      contrastLevel: 1,
    );

    final botonForma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    const textoBoton = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: azul,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 18),
        bodyMedium: TextStyle(fontSize: 17),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: azul,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 56),
          textStyle: textoBoton,
          shape: botonForma,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: azul,
          minimumSize: const Size(64, 56),
          textStyle: textoBoton,
          shape: botonForma,
          side: const BorderSide(color: azul, width: 2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: azul,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
