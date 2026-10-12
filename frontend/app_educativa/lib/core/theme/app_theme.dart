import 'package:flutter/material.dart';

/// Tema "Aprendo", basado en el diseño de Figma, para estudiantes de
/// primaria: letra Nunito grande, botones de al menos 56 px de alto y
/// colores con contraste AA (4,5:1) en todo texto sobre color.
///
/// Los colores fuertes ([verde], [rojo], [ambar]) son versiones más oscuras
/// de los del Figma para que el texto blanco o sobre fondo suave sea legible;
/// los tonos del Figma se usan en barras y fondos ([verdeVivo]).
class AppTheme {
  AppTheme._();

  static const String fuente = 'Nunito';

  // Marca
  static const Color azul = Color(0xFF1E6092);
  static const Color azulClaro = Color(0xFFD8EEFB);
  static const Color azulSuave = Color(0xFFEAF5FD);

  // Superficies
  static const Color fondo = Color(0xFFF5F6FA);
  static const Color superficie = Colors.white;
  static const Color borde = Color(0xFFDDE3EA);

  // Texto
  static const Color texto = Color(0xFF1B2430);
  static const Color textoSecundario = Color(0xFF4A5563);

  // Estados
  static const Color verde = Color(0xFF0B7A55);
  static const Color verdeVivo = Color(0xFF0DBA82);
  static const Color verdeSuave = Color(0xFFDDF7EC);
  static const Color rojo = Color(0xFFC62828);
  static const Color rojoSuave = Color(0xFFFDE8E8);
  static const Color ambar = Color(0xFF8A5A00);
  static const Color ambarSuave = Color(0xFFFFF1CC);
  static const Color gris = Color(0xFF4A5563);
  static const Color grisSuave = Color(0xFFEEF1F5);

  static const double radio = 16;

  static ThemeData get claro {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: azul,
      primary: azul,
      onPrimary: Colors.white,
      primaryContainer: azulClaro,
      onPrimaryContainer: azul,
      error: rojo,
      surface: superficie,
      onSurface: texto,
    );

    final botonForma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    const textoBoton = TextStyle(
      fontFamily: fuente,
      fontSize: 19,
      fontWeight: FontWeight.w800,
    );

    return ThemeData(
      fontFamily: fuente,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: fondo,
      appBarTheme: const AppBarTheme(
        backgroundColor: fondo,
        foregroundColor: texto,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fuente,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: texto,
        ),
      ),
      cardTheme: CardThemeData(
        color: superficie,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radio),
          side: const BorderSide(color: borde),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 18, color: texto),
        bodyMedium: TextStyle(fontSize: 17, color: texto),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: azul,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 56),
          textStyle: textoBoton,
          shape: botonForma,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: azul,
          backgroundColor: superficie,
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
            fontFamily: fuente,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: TextStyle(
          fontFamily: fuente,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: superficie,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: azul, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: superficie,
        indicatorColor: azulClaro,
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith(
          (estados) => IconThemeData(
            size: 28,
            color: estados.contains(WidgetState.selected) ? azul : gris,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (estados) => TextStyle(
            fontFamily: fuente,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: estados.contains(WidgetState.selected) ? azul : gris,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: azul,
        linearTrackColor: grisSuave,
      ),
    );
  }
}
