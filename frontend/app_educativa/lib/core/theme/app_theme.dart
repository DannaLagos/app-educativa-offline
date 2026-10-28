import 'package:flutter/material.dart';

// Colores fuertes oscurecidos respecto al Figma para mantener contraste AA (4,5:1).
class AppTheme {
  AppTheme._();

  static const String fuente = 'Nunito';

  static const Color azul = Color(0xFF1E6092);
  static const Color azulClaro = Color(0xFFD8EEFB);
  static const Color azulSuave = Color(0xFFEAF5FD);

  static const Color fondo = Color(0xFFF5F6FA);
  static const Color superficie = Colors.white;
  static const Color borde = Color(0xFFDDE3EA);

  static const Color texto = Color(0xFF1B2430);
  static const Color textoSecundario = Color(0xFF4A5563);

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
  static const double radioBoton = 12;
  static const double radioDialogo = 20;
  static const double alturaBoton = 56;
  static const double alturaBotonTarjeta = 52;
  static const double alturaBarraNavegacion = 72;
  static const double anchoMinimoBoton = 64;
  static const double tamanoMinimoToque = 48;

  static const TextStyle _textoBoton = TextStyle(
    fontFamily: fuente,
    fontSize: 19,
    fontWeight: FontWeight.w800,
  );

  static ThemeData get claro {
    return ThemeData(
      fontFamily: fuente,
      colorScheme: _esquemaDeColores(),
      scaffoldBackgroundColor: fondo,
      appBarTheme: _temaBarraSuperior(),
      cardTheme: _temaTarjeta(),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 18, color: texto),
        bodyMedium: TextStyle(fontSize: 17, color: texto),
      ),
      elevatedButtonTheme: _temaBotonRelleno(),
      outlinedButtonTheme: _temaBotonContorno(),
      textButtonTheme: _temaBotonTexto(),
      dialogTheme: DialogThemeData(
        backgroundColor: superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioDialogo),
        ),
      ),
      snackBarTheme: _temaSnackBar(),
      inputDecorationTheme: _temaCampoTexto(),
      navigationBarTheme: _temaBarraNavegacion(),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: azul,
        linearTrackColor: grisSuave,
      ),
    );
  }

  static ColorScheme _esquemaDeColores() {
    return ColorScheme.fromSeed(
      seedColor: azul,
      primary: azul,
      onPrimary: Colors.white,
      primaryContainer: azulClaro,
      onPrimaryContainer: azul,
      error: rojo,
      surface: superficie,
      onSurface: texto,
    );
  }

  static AppBarTheme _temaBarraSuperior() {
    return const AppBarTheme(
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
    );
  }

  static CardThemeData _temaTarjeta() {
    return CardThemeData(
      color: superficie,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radio),
        side: const BorderSide(color: borde),
      ),
    );
  }

  static RoundedRectangleBorder _formaBoton() {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radioBoton),
    );
  }

  static ElevatedButtonThemeData _temaBotonRelleno() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: azul,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(anchoMinimoBoton, alturaBoton),
        textStyle: _textoBoton,
        shape: _formaBoton(),
      ),
    );
  }

  static OutlinedButtonThemeData _temaBotonContorno() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: azul,
        backgroundColor: superficie,
        minimumSize: const Size(anchoMinimoBoton, alturaBoton),
        textStyle: _textoBoton,
        shape: _formaBoton(),
        side: const BorderSide(color: azul, width: 2),
      ),
    );
  }

  static TextButtonThemeData _temaBotonTexto() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: azul,
        minimumSize: const Size.square(tamanoMinimoToque),
        textStyle: const TextStyle(
          fontFamily: fuente,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static SnackBarThemeData _temaSnackBar() {
    return const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      contentTextStyle: TextStyle(
        fontFamily: fuente,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  static InputDecorationTheme _temaCampoTexto() {
    return InputDecorationTheme(
      filled: true,
      fillColor: superficie,
      border: _bordeCampo(const BorderSide(color: borde)),
      enabledBorder: _bordeCampo(const BorderSide(color: borde)),
      focusedBorder: _bordeCampo(const BorderSide(color: azul, width: 2)),
    );
  }

  static OutlineInputBorder _bordeCampo(BorderSide lado) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radioBoton),
      borderSide: lado,
    );
  }

  static NavigationBarThemeData _temaBarraNavegacion() {
    return NavigationBarThemeData(
      backgroundColor: superficie,
      indicatorColor: azulClaro,
      height: alturaBarraNavegacion,
      iconTheme: WidgetStateProperty.resolveWith(
        (estados) => IconThemeData(
          size: 28,
          color: _colorSegunSeleccion(estados),
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (estados) => TextStyle(
          fontFamily: fuente,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: _colorSegunSeleccion(estados),
        ),
      ),
    );
  }

  static Color _colorSegunSeleccion(Set<WidgetState> estados) {
    return estados.contains(WidgetState.selected) ? azul : gris;
  }
}
