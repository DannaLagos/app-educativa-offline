import 'package:path/path.dart' as p;

class RecursoModulo {
  final String archivo;
  final String titulo;
  final String tipo;
  final int tamano;
  final String sha256;

  const RecursoModulo({
    required this.archivo,
    required this.titulo,
    required this.tipo,
    required this.tamano,
    required this.sha256,
  });

  factory RecursoModulo.fromJson(Map<String, dynamic> json) {
    final archivo = json['archivo'] as String;

    if (!_estaDentroDeLaCarpeta(archivo)) {
      throw FormatException('Nombre de archivo no permitido: $archivo');
    }

    return RecursoModulo(
      archivo: archivo,
      titulo: json['titulo'] as String,
      tipo: json['tipo'] as String,
      tamano: json['tamano'] as int,
      sha256: json['sha256'] as String,
    );
  }

  static bool _estaDentroDeLaCarpeta(String archivo) {
    return archivo.isNotEmpty &&
        archivo != '..' &&
        p.basename(archivo) == archivo;
  }

  Map<String, dynamic> toJson() {
    return {
      'archivo': archivo,
      'titulo': titulo,
      'tipo': tipo,
      'tamano': tamano,
      'sha256': sha256,
    };
  }
}

class ManifestModulo {
  final String id;
  final int version;
  final List<RecursoModulo> recursos;

  const ManifestModulo({
    required this.id,
    required this.version,
    required this.recursos,
  });

  int get tamanoTotal => recursos.fold(
        0,
        (total, recurso) => total + recurso.tamano,
      );

  factory ManifestModulo.fromJson(Map<String, dynamic> json) {
    return ManifestModulo(
      id: json['id'] as String,
      version: json['version'] as int,
      recursos: (json['recursos'] as List)
          .map(
            (recurso) => RecursoModulo.fromJson(
              recurso as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'recursos': recursos.map((recurso) => recurso.toJson()).toList(),
    };
  }
}
