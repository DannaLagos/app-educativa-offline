import 'modulo.dart';

/// Resumen de un área educativa para la pantalla de áreas: qué grados tiene
/// y cuántos módulos hay disponibles.
class AreaResumen {
  final String area;
  final List<int> grados;
  final int cantidadModulos;

  const AreaResumen({
    required this.area,
    required this.grados,
    required this.cantidadModulos,
  });

  /// "Grado 1 • 1 módulo disponible", "Grados 1 y 3 • 4 módulos disponibles".
  String get descripcion {
    final textoGrados = grados.length == 1
        ? 'Grado ${grados.single}'
        : 'Grados ${grados.sublist(0, grados.length - 1).join(', ')} '
            'y ${grados.last}';
    final textoModulos = cantidadModulos == 1
        ? '1 módulo disponible'
        : '$cantidadModulos módulos disponibles';

    return '$textoGrados • $textoModulos';
  }

  /// Agrupa los módulos por área, en orden alfabético.
  static List<AreaResumen> agrupar(List<Modulo> modulos) {
    final porArea = <String, List<Modulo>>{};

    for (final modulo in modulos) {
      porArea.putIfAbsent(modulo.area, () => []).add(modulo);
    }

    final areas = porArea.keys.toList()..sort();

    return [
      for (final area in areas)
        AreaResumen(
          area: area,
          grados: (porArea[area]!.map((modulo) => modulo.grado).toSet().toList()
            ..sort()),
          cantidadModulos: porArea[area]!.length,
        ),
    ];
  }
}
