/// Datos sincronizados tal como están en Firestore (HU14). Cada registro
/// trae `perfil_id` y `modulo_id`; los campos son los de las tablas de
/// progreso de SQLite (ver `documentosDeProgreso`).
class DatosUso {
  /// `estudiantes/{perfil}`: perfil_id, nombre y `sincronizado_en`
  /// (convertido a [DateTime]).
  final List<Map<String, Object?>> estudiantes;
  final List<Map<String, Object?>> modulos;
  final List<Map<String, Object?>> lecturas;
  final List<Map<String, Object?>> actividades;

  /// Nombre de cada módulo según el catálogo, por id.
  final Map<String, String> nombresModulos;

  const DatosUso({
    this.estudiantes = const [],
    this.modulos = const [],
    this.lecturas = const [],
    this.actividades = const [],
    this.nombresModulos = const {},
  });
}

class UsoModulo {
  final String moduloId;
  final String nombre;
  final int estudiantes;

  /// Promedio del porcentaje de los estudiantes que lo usan (0 a 100).
  final int avancePromedio;
  final int actividadesCompletadas;
  final int intentos;
  final int paginasLeidas;

  const UsoModulo({
    required this.moduloId,
    required this.nombre,
    required this.estudiantes,
    required this.avancePromedio,
    required this.actividadesCompletadas,
    required this.intentos,
    required this.paginasLeidas,
  });
}

class UsoEstudiante {
  final String perfilId;
  final String nombre;
  final int modulosUsados;
  final int actividadesCompletadas;
  final int avancePromedio;
  final DateTime? ultimaSincronizacion;

  const UsoEstudiante({
    required this.perfilId,
    required this.nombre,
    required this.modulosUsados,
    required this.actividadesCompletadas,
    required this.avancePromedio,
    required this.ultimaSincronizacion,
  });
}

/// Resumen general del uso de la aplicación (HU14, criterio 2). Solo incluye
/// lo que ya llegó al servidor: lo pendiente en un teléfono aparece cuando
/// ese teléfono sincroniza (criterio 3).
class ResumenUso {
  final int totalEstudiantes;
  final int actividadesCompletadas;
  final int intentos;
  final int paginasLeidas;
  final int avancePromedio;

  /// Ordenados del más usado al menos usado.
  final List<UsoModulo> modulos;

  /// Ordenados del que sincronizó más recientemente al más antiguo.
  final List<UsoEstudiante> estudiantes;

  const ResumenUso({
    required this.totalEstudiantes,
    required this.actividadesCompletadas,
    required this.intentos,
    required this.paginasLeidas,
    required this.avancePromedio,
    required this.modulos,
    required this.estudiantes,
  });

  bool get estaVacio => totalEstudiantes == 0 && modulos.isEmpty;

  factory ResumenUso.calcular(DatosUso datos) {
    final porModulo = <String, _Acumulado>{};
    final porEstudiante = <String, _Acumulado>{};

    _Acumulado de(Map<String, _Acumulado> mapa, Object? clave) {
      return mapa.putIfAbsent('$clave', _Acumulado.new);
    }

    void registrarUso(Map<String, Object?> fila) {
      de(porModulo, fila['modulo_id']).perfiles.add('${fila['perfil_id']}');
      de(porEstudiante, fila['perfil_id']).modulos.add('${fila['modulo_id']}');
    }

    for (final fila in datos.modulos) {
      registrarUso(fila);
      final porcentaje = _entero(fila['porcentaje']);
      de(porModulo, fila['modulo_id']).porcentajes.add(porcentaje);
      de(porEstudiante, fila['perfil_id']).porcentajes.add(porcentaje);
    }

    for (final fila in datos.lecturas) {
      registrarUso(fila);
      de(porModulo, fila['modulo_id']).paginas += _entero(fila['pagina_maxima']);
    }

    for (final fila in datos.actividades) {
      registrarUso(fila);
      final completada = _esVerdadero(fila['completada']) ? 1 : 0;
      de(porModulo, fila['modulo_id'])
        ..completadas += completada
        ..intentos += _entero(fila['intentos']);
      de(porEstudiante, fila['perfil_id']).completadas += completada;
    }

    final estudiantes = <String, Map<String, Object?>>{
      for (final fila in datos.estudiantes) '${fila['perfil_id']}': fila,
    };

    final usoModulos = [
      for (final MapEntry(key: id, value: acumulado) in porModulo.entries)
        UsoModulo(
          moduloId: id,
          nombre: datos.nombresModulos[id] ?? id,
          estudiantes: acumulado.perfiles.length,
          avancePromedio: _promedio(acumulado.porcentajes),
          actividadesCompletadas: acumulado.completadas,
          intentos: acumulado.intentos,
          paginasLeidas: acumulado.paginas,
        ),
    ]..sort((a, b) => b.estudiantes != a.estudiantes
        ? b.estudiantes.compareTo(a.estudiantes)
        : a.nombre.compareTo(b.nombre));

    final usoEstudiantes = [
      for (final perfilId in {...estudiantes.keys, ...porEstudiante.keys})
        UsoEstudiante(
          perfilId: perfilId,
          nombre: estudiantes[perfilId]?['nombre'] as String? ?? 'Sin nombre',
          modulosUsados: porEstudiante[perfilId]?.modulos.length ?? 0,
          actividadesCompletadas: porEstudiante[perfilId]?.completadas ?? 0,
          avancePromedio: _promedio(porEstudiante[perfilId]?.porcentajes ?? []),
          ultimaSincronizacion:
              estudiantes[perfilId]?['sincronizado_en'] as DateTime?,
        ),
    ]..sort(_porSincronizacionReciente);

    return ResumenUso(
      totalEstudiantes: usoEstudiantes.length,
      actividadesCompletadas:
          usoModulos.fold(0, (suma, m) => suma + m.actividadesCompletadas),
      intentos: usoModulos.fold(0, (suma, m) => suma + m.intentos),
      paginasLeidas: usoModulos.fold(0, (suma, m) => suma + m.paginasLeidas),
      avancePromedio: _promedio([
        for (final acumulado in porModulo.values) ...acumulado.porcentajes,
      ]),
      modulos: usoModulos,
      estudiantes: usoEstudiantes,
    );
  }
}

class _Acumulado {
  final Set<String> perfiles = {};
  final Set<String> modulos = {};
  final List<int> porcentajes = [];
  int completadas = 0;
  int intentos = 0;
  int paginas = 0;
}

int _porSincronizacionReciente(UsoEstudiante a, UsoEstudiante b) {
  final fechaA = a.ultimaSincronizacion;
  final fechaB = b.ultimaSincronizacion;

  if (fechaA == null || fechaB == null) {
    return fechaA == fechaB ? a.nombre.compareTo(b.nombre) : (fechaA == null ? 1 : -1);
  }

  return fechaB.compareTo(fechaA);
}

int _promedio(List<int> valores) {
  if (valores.isEmpty) return 0;

  return (valores.reduce((a, b) => a + b) / valores.length).round();
}

// SQLite guarda los booleanos como 0/1 y así llegan a Firestore.
bool _esVerdadero(Object? valor) => valor == true || valor == 1;

int _entero(Object? valor) => valor is num ? valor.toInt() : 0;
