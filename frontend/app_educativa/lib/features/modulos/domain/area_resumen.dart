import 'modulo.dart';

class AreaResumen {
  final String area;
  final List<int> grados;
  final int cantidadModulos;

  const AreaResumen({
    required this.area,
    required this.grados,
    required this.cantidadModulos,
  });

  String get descripcion => '${_describirGrados()} • ${_describirModulos()}';

  String _describirGrados() {
    if (grados.length == 1) {
      return 'Grado ${grados.single}';
    }

    final gradosIniciales = grados.sublist(0, grados.length - 1).join(', ');

    return 'Grados $gradosIniciales y ${grados.last}';
  }

  String _describirModulos() {
    if (cantidadModulos == 1) {
      return '1 módulo disponible';
    }

    return '$cantidadModulos módulos disponibles';
  }

  static List<AreaResumen> agrupar(List<Modulo> modulos) {
    final modulosPorArea = <String, List<Modulo>>{};

    for (final modulo in modulos) {
      modulosPorArea.putIfAbsent(modulo.area, () => []).add(modulo);
    }

    final areasOrdenadas = modulosPorArea.keys.toList()..sort();

    return [
      for (final area in areasOrdenadas)
        AreaResumen._desdeModulos(area, modulosPorArea[area]!),
    ];
  }

  factory AreaResumen._desdeModulos(String area, List<Modulo> modulos) {
    final gradosOrdenados =
        modulos.map((modulo) => modulo.grado).toSet().toList()..sort();

    return AreaResumen(
      area: area,
      grados: gradosOrdenados,
      cantidadModulos: modulos.length,
    );
  }
}
