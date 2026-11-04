/// Mascotas que el estudiante puede elegir al crear su perfil. Son
/// personajes ficticios dibujados por la app, así funcionan sin internet.
enum EspecieMascota {
  chispa(
    nombre: 'Chispa',
    descripcion: 'Un dragoncito valiente que ama los retos.',
  ),
  burbu(
    nombre: 'Burbu',
    descripcion: 'Un ajolote curioso que explora el agua.',
  ),
  lumi(
    nombre: 'Lumi',
    descripcion: 'Un zorrito estelar que brilla al aprender.',
  ),
  brote(
    nombre: 'Brote',
    descripcion: 'Una plantita que crece con cada juego.',
  ),
  nimbo(
    nombre: 'Nimbo',
    descripcion: 'Una nubecita eléctrica llena de ideas.',
  );

  final String nombre;
  final String descripcion;

  const EspecieMascota({required this.nombre, required this.descripcion});

  /// Nombres para tocar en vez de escribir (para quien aún no escribe
  /// bien). El primero es el de la especie.
  List<String> get nombresSugeridos => switch (this) {
        EspecieMascota.chispa => const ['Chispa', 'Fueguito', 'Dragui'],
        EspecieMascota.burbu => const ['Burbu', 'Ajolín', 'Coral'],
        EspecieMascota.lumi => const ['Lumi', 'Estrellita', 'Zorrito'],
        EspecieMascota.brote => const ['Brote', 'Hojita', 'Semillín'],
        EspecieMascota.nimbo => const ['Nimbo', 'Nubecita', 'Rayito'],
      };

  /// null si [id] no es una mascota conocida (por ejemplo, un perfil creado
  /// antes de que existieran las mascotas).
  static EspecieMascota? desdeId(String? id) {
    for (final especie in values) {
      if (especie.name == id) {
        return especie;
      }
    }
    return null;
  }
}

/// La mascota de un niño: su especie y el nombre que él le puso.
class MascotaElegida {
  final EspecieMascota especie;
  final String nombre;

  const MascotaElegida({required this.especie, required this.nombre});

  /// Sin nombre propio (perfiles anteriores), se llama como su especie.
  factory MascotaElegida.de(EspecieMascota especie, [String? nombre]) {
    final limpio = nombre?.trim() ?? '';

    return MascotaElegida(
      especie: especie,
      nombre: limpio.isEmpty ? especie.nombre : limpio,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MascotaElegida &&
      other.especie == especie &&
      other.nombre == nombre;

  @override
  int get hashCode => Object.hash(especie, nombre);
}

/// Etapas de evolución. La mascota avanza con las estrellas que el
/// estudiante gana en los juegos de todos sus módulos.
enum EtapaMascota {
  huevo(nombre: 'Huevo', estrellasMinimas: 0),
  bebe(nombre: 'Bebé', estrellasMinimas: 3),
  exploradora(nombre: 'Exploradora', estrellasMinimas: 15),
  leyenda(nombre: 'Leyenda', estrellasMinimas: 40);

  final String nombre;
  final int estrellasMinimas;

  const EtapaMascota({required this.nombre, required this.estrellasMinimas});

  EtapaMascota? get siguiente =>
      index + 1 < values.length ? values[index + 1] : null;

  static EtapaMascota segunEstrellas(int estrellas) {
    return values.lastWhere((etapa) => estrellas >= etapa.estrellasMinimas);
  }
}

/// En qué etapa está la mascota y cuánto le falta para la siguiente.
class EvolucionMascota {
  final int estrellas;
  final EtapaMascota etapa;

  EvolucionMascota(this.estrellas)
      : etapa = EtapaMascota.segunEstrellas(estrellas);

  bool get esUltimaEtapa => etapa.siguiente == null;

  /// Estrellas que faltan para evolucionar (0 en la última etapa).
  int get estrellasFaltantes {
    final siguiente = etapa.siguiente;
    return siguiente == null ? 0 : siguiente.estrellasMinimas - estrellas;
  }

  /// De 0 a 1: avance dentro de la etapa actual.
  double get avance {
    final siguiente = etapa.siguiente;

    if (siguiente == null) {
      return 1;
    }

    final tramo = siguiente.estrellasMinimas - etapa.estrellasMinimas;
    return (estrellas - etapa.estrellasMinimas) / tramo;
  }
}
