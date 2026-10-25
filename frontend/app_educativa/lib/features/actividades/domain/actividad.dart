/// Modelo de las actividades y juegos de un módulo (HU07).
///
/// Se leen de `actividades.json`, que se descarga con el módulo desde
/// Firebase Storage. Así los juegos funcionan sin internet y se pueden
/// agregar o corregir sin reprogramar la app.
library;

/// Un dibujo (emoji) con su texto. Los emojis funcionan sin internet y son
/// fáciles de reconocer para niños que aún no leen bien.
class ElementoVisual {
  final String emoji;
  final String texto;

  const ElementoVisual({required this.emoji, required this.texto});

  factory ElementoVisual.fromJson(Object? json) {
    final mapa = _mapa(json, 'elemento');

    return ElementoVisual(
      emoji: _texto(mapa, 'emoji'),
      texto: _texto(mapa, 'texto'),
    );
  }
}

/// Ayuda para quien no sabe la respuesta: un fragmento de la cartilla y la
/// página del PDF donde está, para ir a buscarla.
class Pista {
  final String texto;

  /// Página del PDF del módulo (empieza en 1), o null si no viene de la
  /// cartilla.
  final int? pagina;

  const Pista({required this.texto, this.pagina});

  /// Lee una pista opcional: devuelve null si no hay.
  static Pista? desdeJson(Object? json) {
    if (json == null) {
      return null;
    }

    final mapa = _mapa(json, 'pista');
    final pagina = mapa['pagina'];

    if (pagina != null && (pagina is! int || pagina < 1)) {
      throw FormatException('Página de pista inválida: $pagina');
    }

    return Pista(texto: _texto(mapa, 'texto'), pagina: pagina as int?);
  }
}

enum TipoActividad {
  elige('elige'),
  parejas('parejas'),
  clasifica('clasifica'),
  ordena('ordena'),
  memoria('memoria'),
  arrastra('arrastra'),
  atrapa('atrapa'),
  completa('completa'),
  arma('arma'),
  sopa('sopa');

  final String valor;

  const TipoActividad(this.valor);

  static TipoActividad desdeValor(String valor) {
    for (final tipo in values) {
      if (tipo.valor == valor) {
        return tipo;
      }
    }

    throw FormatException('Tipo de actividad desconocido: $valor');
  }
}

/// Una actividad o juego. Cada tipo tiene su propia subclase.
sealed class Actividad {
  final String id;
  final String titulo;

  /// Se muestra y se lee en voz alta al empezar.
  final String instruccion;

  /// Pista de toda la actividad (opcional).
  final Pista? pista;

  const Actividad({
    required this.id,
    required this.titulo,
    required this.instruccion,
    this.pista,
  });

  TipoActividad get tipo;

  /// Cuántos aciertos hacen falta para terminar.
  int get totalAciertos;

  factory Actividad.fromJson(Object? json) {
    final mapa = _mapa(json, 'actividad');
    final id = _texto(mapa, 'id');
    final titulo = _texto(mapa, 'titulo');
    final instruccion = _texto(mapa, 'instruccion');
    final pista = Pista.desdeJson(mapa['pista']);

    final actividad = switch (TipoActividad.desdeValor(_texto(mapa, 'tipo'))) {
      TipoActividad.elige => ActividadElige(
          id: id,
          titulo: titulo,
          instruccion: instruccion,
          pista: pista,
          preguntas: _lista(mapa, 'preguntas', PreguntaElige.fromJson),
        ),
      TipoActividad.parejas => ActividadParejas(
          id: id,
          titulo: titulo,
          instruccion: instruccion,
          pista: pista,
          pares: _lista(mapa, 'pares', Pareja.fromJson),
        ),
      TipoActividad.clasifica => ActividadClasifica.validada(
          id: id,
          titulo: titulo,
          instruccion: instruccion,
          pista: pista,
          grupos: _lista(mapa, 'grupos', GrupoClasifica.fromJson),
          tarjetas: _lista(mapa, 'tarjetas', TarjetaClasifica.fromJson),
        ),
      TipoActividad.ordena => ActividadOrdena(
          id: id,
          titulo: titulo,
          instruccion: instruccion,
          pista: pista,
          pasos: _lista(mapa, 'pasos', ElementoVisual.fromJson),
        ),
      TipoActividad.memoria => ActividadMemoria(
          id: id,
          titulo: titulo,
          instruccion: instruccion,
          pista: pista,
          pares: _lista(mapa, 'pares', Pareja.fromJson),
        ),
      TipoActividad.arrastra => ActividadArrastra.validada(
          id: id,
          titulo: titulo,
          instruccion: instruccion,
          pista: pista,
          grupos: _lista(mapa, 'grupos', GrupoClasifica.fromJson),
          tarjetas: _lista(mapa, 'tarjetas', TarjetaClasifica.fromJson),
        ),
      TipoActividad.completa => ActividadCompleta(
          id: id,
          titulo: titulo,
          instruccion: instruccion,
          pista: pista,
          oraciones: _lista(mapa, 'oraciones', OracionCompleta.fromJson),
        ),
      TipoActividad.arma => ActividadArma(
          id: id,
          titulo: titulo,
          instruccion: instruccion,
          pista: pista,
          oraciones: _lista(mapa, 'oraciones', OracionArma.fromJson),
        ),
      TipoActividad.sopa => ActividadSopa.validada(
          id: id,
          titulo: titulo,
          instruccion: instruccion,
          pista: pista,
          palabras: _lista(mapa, 'palabras', ElementoVisual.fromJson),
          tamano: mapa['tamano'],
        ),
      TipoActividad.atrapa => ActividadAtrapa.validada(
          id: id,
          titulo: titulo,
          instruccion: instruccion,
          pista: pista,
          objetivo: ElementoVisual.fromJson(mapa['objetivo']),
          elementos: _lista(mapa, 'elementos', ElementoAtrapa.fromJson),
        ),
    };

    if (actividad.totalAciertos == 0) {
      throw FormatException('La actividad $id no tiene contenido.');
    }

    return actividad;
  }
}

/// Elegir la respuesta correcta entre 2 o 3 opciones.
class ActividadElige extends Actividad {
  final List<PreguntaElige> preguntas;

  const ActividadElige({
    required super.id,
    required super.titulo,
    required super.instruccion,
    super.pista,
    required this.preguntas,
  });

  @override
  TipoActividad get tipo => TipoActividad.elige;

  @override
  int get totalAciertos => preguntas.length;
}

class PreguntaElige {
  final String enunciado;
  final List<ElementoVisual> opciones;

  /// Posición de la opción correcta en [opciones].
  final int correcta;

  /// Pista de esta pregunta (opcional).
  final Pista? pista;

  const PreguntaElige({
    required this.enunciado,
    required this.opciones,
    required this.correcta,
    this.pista,
  });

  ElementoVisual get respuesta => opciones[correcta];

  factory PreguntaElige.fromJson(Object? json) {
    final mapa = _mapa(json, 'pregunta');
    final opciones = _lista(mapa, 'opciones', ElementoVisual.fromJson);
    final correcta = mapa['correcta'];

    if (opciones.length < 2) {
      throw const FormatException('Una pregunta necesita al menos 2 opciones.');
    }
    if (correcta is! int || correcta < 0 || correcta >= opciones.length) {
      throw FormatException('Respuesta correcta inválida: $correcta');
    }

    return PreguntaElige(
      enunciado: _texto(mapa, 'enunciado'),
      opciones: opciones,
      correcta: correcta,
      pista: Pista.desdeJson(mapa['pista']),
    );
  }
}

/// Unir cada elemento de la izquierda con su pareja de la derecha.
class ActividadParejas extends Actividad {
  final List<Pareja> pares;

  const ActividadParejas({
    required super.id,
    required super.titulo,
    required super.instruccion,
    super.pista,
    required this.pares,
  });

  @override
  TipoActividad get tipo => TipoActividad.parejas;

  @override
  int get totalAciertos => pares.length;
}

class Pareja {
  final ElementoVisual izquierda;
  final ElementoVisual derecha;

  const Pareja({required this.izquierda, required this.derecha});

  factory Pareja.fromJson(Object? json) {
    final mapa = _mapa(json, 'pareja');

    return Pareja(
      izquierda: ElementoVisual.fromJson(mapa['izquierda']),
      derecha: ElementoVisual.fromJson(mapa['derecha']),
    );
  }
}

/// Poner cada tarjeta en el grupo (canasta) correcto.
class ActividadClasifica extends Actividad {
  final List<GrupoClasifica> grupos;
  final List<TarjetaClasifica> tarjetas;

  const ActividadClasifica({
    required super.id,
    required super.titulo,
    required super.instruccion,
    super.pista,
    required this.grupos,
    required this.tarjetas,
  });

  factory ActividadClasifica.validada({
    required String id,
    required String titulo,
    required String instruccion,
    Pista? pista,
    required List<GrupoClasifica> grupos,
    required List<TarjetaClasifica> tarjetas,
  }) {
    _validarGrupos(id, grupos, tarjetas);

    return ActividadClasifica(
      id: id,
      titulo: titulo,
      instruccion: instruccion,
      pista: pista,
      grupos: grupos,
      tarjetas: tarjetas,
    );
  }

  @override
  TipoActividad get tipo => TipoActividad.clasifica;

  @override
  int get totalAciertos => tarjetas.length;
}

class GrupoClasifica {
  final String id;
  final ElementoVisual elemento;

  const GrupoClasifica({required this.id, required this.elemento});

  factory GrupoClasifica.fromJson(Object? json) {
    final mapa = _mapa(json, 'grupo');

    return GrupoClasifica(
      id: _texto(mapa, 'id'),
      elemento: ElementoVisual.fromJson(mapa),
    );
  }
}

class TarjetaClasifica {
  final ElementoVisual elemento;

  /// Id del [GrupoClasifica] al que pertenece.
  final String grupo;

  const TarjetaClasifica({required this.elemento, required this.grupo});

  factory TarjetaClasifica.fromJson(Object? json) {
    final mapa = _mapa(json, 'tarjeta');

    return TarjetaClasifica(
      elemento: ElementoVisual.fromJson(mapa),
      grupo: _texto(mapa, 'grupo'),
    );
  }
}

/// Tocar los pasos en el orden correcto. En el JSON van en orden; la app
/// los muestra mezclados.
class ActividadOrdena extends Actividad {
  final List<ElementoVisual> pasos;

  const ActividadOrdena({
    required super.id,
    required super.titulo,
    required super.instruccion,
    super.pista,
    required this.pasos,
  });

  @override
  TipoActividad get tipo => TipoActividad.ordena;

  @override
  int get totalAciertos => pasos.length;
}

/// Memoria: voltear cartas de dos en dos hasta encontrar cada pareja.
/// Usa los mismos datos que Parejas, pero las cartas están boca abajo.
class ActividadMemoria extends Actividad {
  final List<Pareja> pares;

  const ActividadMemoria({
    required super.id,
    required super.titulo,
    required super.instruccion,
    super.pista,
    required this.pares,
  });

  @override
  TipoActividad get tipo => TipoActividad.memoria;

  @override
  int get totalAciertos => pares.length;
}

/// Arrastra y suelta: llevar con el dedo cada tarjeta a su canasta. Usa los
/// mismos datos que Clasifica, pero todas las tarjetas están a la vista.
class ActividadArrastra extends Actividad {
  final List<GrupoClasifica> grupos;
  final List<TarjetaClasifica> tarjetas;

  const ActividadArrastra({
    required super.id,
    required super.titulo,
    required super.instruccion,
    super.pista,
    required this.grupos,
    required this.tarjetas,
  });

  factory ActividadArrastra.validada({
    required String id,
    required String titulo,
    required String instruccion,
    Pista? pista,
    required List<GrupoClasifica> grupos,
    required List<TarjetaClasifica> tarjetas,
  }) {
    _validarGrupos(id, grupos, tarjetas);

    return ActividadArrastra(
      id: id,
      titulo: titulo,
      instruccion: instruccion,
      pista: pista,
      grupos: grupos,
      tarjetas: tarjetas,
    );
  }

  @override
  TipoActividad get tipo => TipoActividad.arrastra;

  @override
  int get totalAciertos => tarjetas.length;
}

/// Atrapa: los dibujos suben como globos y el niño revienta solo los que
/// cumplen el [objetivo].
class ActividadAtrapa extends Actividad {
  final ElementoVisual objetivo;
  final List<ElementoAtrapa> elementos;

  const ActividadAtrapa({
    required super.id,
    required super.titulo,
    required super.instruccion,
    super.pista,
    required this.objetivo,
    required this.elementos,
  });

  factory ActividadAtrapa.validada({
    required String id,
    required String titulo,
    required String instruccion,
    Pista? pista,
    required ElementoVisual objetivo,
    required List<ElementoAtrapa> elementos,
  }) {
    final correctos = elementos.where((e) => e.esCorrecto).length;

    if (correctos == 0 || correctos == elementos.length) {
      throw FormatException(
        'La actividad $id necesita globos correctos e incorrectos.',
      );
    }

    return ActividadAtrapa(
      id: id,
      titulo: titulo,
      instruccion: instruccion,
      pista: pista,
      objetivo: objetivo,
      elementos: elementos,
    );
  }

  @override
  TipoActividad get tipo => TipoActividad.atrapa;

  @override
  int get totalAciertos => elementos.where((e) => e.esCorrecto).length;
}

class ElementoAtrapa {
  final ElementoVisual elemento;
  final bool esCorrecto;

  const ElementoAtrapa({required this.elemento, required this.esCorrecto});

  factory ElementoAtrapa.fromJson(Object? json) {
    final mapa = _mapa(json, 'globo');
    final correcto = mapa['correcto'];

    if (correcto is! bool) {
      throw const FormatException('Cada globo necesita "correcto": true/false.');
    }

    return ElementoAtrapa(
      elemento: ElementoVisual.fromJson(mapa),
      esCorrecto: correcto,
    );
  }
}

/// Completa: una oración con un espacio en blanco (`___`) y varias palabras
/// para llenarlo.
class ActividadCompleta extends Actividad {
  final List<OracionCompleta> oraciones;

  const ActividadCompleta({
    required super.id,
    required super.titulo,
    required super.instruccion,
    super.pista,
    required this.oraciones,
  });

  @override
  TipoActividad get tipo => TipoActividad.completa;

  @override
  int get totalAciertos => oraciones.length;
}

class OracionCompleta {
  static const String espacio = '___';

  final String emoji;

  /// Texto con un único `___` donde va la palabra.
  final String texto;
  final List<String> opciones;
  final int correcta;

  /// Pista de esta oración (opcional).
  final Pista? pista;

  const OracionCompleta({
    required this.emoji,
    required this.texto,
    required this.opciones,
    required this.correcta,
    this.pista,
  });

  String get antes => texto.split(espacio).first;

  String get despues => texto.split(espacio).last;

  String get respuesta => opciones[correcta];

  /// La oración completa, para leerla en voz alta.
  String get textoCompleto => texto.replaceFirst(espacio, respuesta);

  factory OracionCompleta.fromJson(Object? json) {
    final mapa = _mapa(json, 'oración');
    final texto = _texto(mapa, 'texto');
    final opciones = mapa['opciones'];
    final correcta = mapa['correcta'];

    if (espacio.allMatches(texto).length != 1) {
      throw FormatException('La oración debe tener un solo "___": $texto');
    }
    if (opciones is! List ||
        opciones.length < 2 ||
        opciones.any((opcion) => opcion is! String)) {
      throw FormatException('Faltan las opciones de: $texto');
    }
    if (correcta is! int || correcta < 0 || correcta >= opciones.length) {
      throw FormatException('Respuesta correcta inválida en: $texto');
    }

    return OracionCompleta(
      emoji: _texto(mapa, 'emoji'),
      texto: texto,
      opciones: opciones.cast<String>(),
      correcta: correcta,
      pista: Pista.desdeJson(mapa['pista']),
    );
  }
}

/// Arma la oración: tocar las palabras en orden para formar la oración.
/// En el JSON van en orden; la app las muestra mezcladas.
class ActividadArma extends Actividad {
  final List<OracionArma> oraciones;

  const ActividadArma({
    required super.id,
    required super.titulo,
    required super.instruccion,
    super.pista,
    required this.oraciones,
  });

  @override
  TipoActividad get tipo => TipoActividad.arma;

  @override
  int get totalAciertos =>
      oraciones.fold(0, (total, oracion) => total + oracion.partes.length);
}

class OracionArma {
  final String emoji;
  final List<String> partes;

  const OracionArma({required this.emoji, required this.partes});

  String get texto => partes.join(' ');

  factory OracionArma.fromJson(Object? json) {
    final mapa = _mapa(json, 'oración');
    final partes = mapa['partes'];

    if (partes is! List ||
        partes.length < 2 ||
        partes.any((parte) => parte is! String || parte.trim().isEmpty)) {
      throw const FormatException('Una oración necesita al menos 2 partes.');
    }

    return OracionArma(
      emoji: _texto(mapa, 'emoji'),
      partes: partes.cast<String>(),
    );
  }
}

/// Sopa de letras: encontrar palabras escondidas en una cuadrícula. La
/// cuadrícula se genera en la app, en horizontal (→) y vertical (↓).
class ActividadSopa extends Actividad {
  static const int tamanoMinimo = 6;
  static const int tamanoMaximo = 12;

  /// Las palabras a encontrar (el texto se normaliza a mayúsculas sin
  /// tildes al armar la cuadrícula).
  final List<ElementoVisual> palabras;
  final int tamano;

  const ActividadSopa({
    required super.id,
    required super.titulo,
    required super.instruccion,
    super.pista,
    required this.palabras,
    required this.tamano,
  });

  factory ActividadSopa.validada({
    required String id,
    required String titulo,
    required String instruccion,
    Pista? pista,
    required List<ElementoVisual> palabras,
    required Object? tamano,
  }) {
    final masLarga = palabras.fold(
      0,
      (largo, palabra) => largo > normalizarPalabra(palabra.texto).length
          ? largo
          : normalizarPalabra(palabra.texto).length,
    );
    final lado = tamano is int ? tamano : (masLarga + 2);

    if (lado < masLarga || lado > tamanoMaximo || lado < tamanoMinimo) {
      throw FormatException(
        'Tamaño de sopa inválido en $id: $lado (palabra más larga: $masLarga).',
      );
    }
    for (final palabra in palabras) {
      if (!RegExp(r'^[A-ZÑ]+$').hasMatch(normalizarPalabra(palabra.texto))) {
        throw FormatException('Palabra no válida para la sopa: ${palabra.texto}');
      }
    }

    return ActividadSopa(
      id: id,
      titulo: titulo,
      instruccion: instruccion,
      pista: pista,
      palabras: palabras,
      tamano: lado,
    );
  }

  @override
  TipoActividad get tipo => TipoActividad.sopa;

  @override
  int get totalAciertos => palabras.length;
}

/// Mayúsculas sin tildes ni espacios (la Ñ se conserva).
String normalizarPalabra(String texto) {
  const tildes = {'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ü': 'U'};

  return texto
      .toUpperCase()
      .split('')
      .map((letra) => tildes[letra] ?? letra)
      .join()
      .replaceAll(' ', '');
}

/// Un nivel agrupa actividades de un mismo tema, de fácil a difícil.
class Nivel {
  final String id;
  final int numero;
  final String titulo;
  final String emoji;

  /// Lo que el niño aprende (relacionado con los estándares).
  final String objetivo;
  final List<Actividad> actividades;

  const Nivel({
    required this.id,
    required this.numero,
    required this.titulo,
    required this.emoji,
    required this.objetivo,
    required this.actividades,
  });

  factory Nivel.fromJson(Object? json) {
    final mapa = _mapa(json, 'nivel');
    final numero = mapa['numero'];

    if (numero is! int) {
      throw FormatException('Número de nivel inválido: $numero');
    }

    return Nivel(
      id: _texto(mapa, 'id'),
      numero: numero,
      titulo: _texto(mapa, 'titulo'),
      emoji: _texto(mapa, 'emoji'),
      objetivo: _texto(mapa, 'objetivo'),
      actividades: _lista(mapa, 'actividades', Actividad.fromJson),
    );
  }
}

/// Todos los niveles de un módulo, en el orden en que se deben jugar.
class PlanActividades {
  final List<Nivel> niveles;

  const PlanActividades({required this.niveles});

  /// Todas las actividades en orden (nivel 1, luego nivel 2...).
  List<Actividad> get actividades => [
        for (final nivel in niveles) ...nivel.actividades,
      ];

  factory PlanActividades.fromJson(Object? json) {
    final mapa = _mapa(json, 'plan de actividades');
    final niveles = _lista(mapa, 'niveles', Nivel.fromJson)
      ..sort((a, b) => a.numero.compareTo(b.numero));

    final ids = <String>{};
    for (final nivel in niveles) {
      for (final actividad in nivel.actividades) {
        if (!ids.add(actividad.id)) {
          throw FormatException('Id de actividad repetido: ${actividad.id}');
        }
      }
    }

    return PlanActividades(niveles: niveles);
  }
}

void _validarGrupos(
  String id,
  List<GrupoClasifica> grupos,
  List<TarjetaClasifica> tarjetas,
) {
  if (grupos.length < 2) {
    throw FormatException('La actividad $id necesita al menos 2 grupos.');
  }

  final idsGrupos = grupos.map((grupo) => grupo.id).toSet();

  for (final tarjeta in tarjetas) {
    if (!idsGrupos.contains(tarjeta.grupo)) {
      throw FormatException(
        'La tarjeta "${tarjeta.elemento.texto}" usa un grupo que no existe: '
        '${tarjeta.grupo}',
      );
    }
  }
}

Map<String, Object?> _mapa(Object? json, String que) {
  if (json is Map<String, Object?>) {
    return json;
  }
  if (json is Map) {
    return json.cast<String, Object?>();
  }

  throw FormatException('Se esperaba un objeto para $que.');
}

String _texto(Map<String, Object?> mapa, String clave) {
  final valor = mapa[clave];

  if (valor is! String || valor.trim().isEmpty) {
    throw FormatException('Falta el texto "$clave".');
  }

  return valor;
}

List<T> _lista<T>(
  Map<String, Object?> mapa,
  String clave,
  T Function(Object? json) convertir,
) {
  final valor = mapa[clave];

  if (valor is! List) {
    throw FormatException('Falta la lista "$clave".');
  }

  return valor.map(convertir).toList();
}
