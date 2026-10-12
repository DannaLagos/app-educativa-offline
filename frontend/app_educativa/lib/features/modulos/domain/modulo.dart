import 'dart:convert';

import 'estado_descarga.dart';

class Modulo {
  final String id;
  final String nombre;
  final String area;
  final int grado;
  final String descripcion;
  final int version;
  final bool habilitado;
  final List<String> contenidos;
  final EstadoDescarga estadoDescarga;
  final String? rutaLocal;
  final DateTime? fechaDescarga;

  const Modulo({
    required this.id,
    required this.nombre,
    required this.area,
    required this.grado,
    required this.descripcion,
    required this.version,
    required this.habilitado,
    this.contenidos = const [],
    this.estadoDescarga = EstadoDescarga.noDescargado,
    this.rutaLocal,
    this.fechaDescarga,
  });

  bool get estaDescargado => estadoDescarga == EstadoDescarga.descargado;

  /// Construye el módulo a partir de una entrada de catalogo.json.
  factory Modulo.desdeCatalogo(Map<String, dynamic> json) {
    return Modulo(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      area: json['area'] as String,
      grado: json['grado'] as int,
      descripcion: json['descripcion'] as String,
      version: json['version'] as int,
      habilitado: json['habilitado'] as bool,
      contenidos: List<String>.from(
        json['contenidos'] as List? ?? const [],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'area': area,
      'grado': grado,
      'descripcion': descripcion,
      'version': version,
      'habilitado': habilitado ? 1 : 0,
      'contenidos': jsonEncode(contenidos),
      'estado_descarga': estadoDescarga.valor,
      'ruta_local': rutaLocal,
      'fecha_descarga': fechaDescarga?.toIso8601String(),
    };
  }

  factory Modulo.fromMap(Map<String, dynamic> map) {
    final fechaDescarga = map['fecha_descarga'] as String?;

    return Modulo(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      area: map['area'] as String,
      grado: map['grado'] as int,
      descripcion: map['descripcion'] as String,
      version: map['version'] as int,
      habilitado: map['habilitado'] == 1,
      contenidos: List<String>.from(
        jsonDecode(map['contenidos'] as String? ?? '[]') as List,
      ),
      estadoDescarga: EstadoDescarga.desdeValor(
        map['estado_descarga'] as String?,
      ),
      rutaLocal: map['ruta_local'] as String?,
      fechaDescarga:
          fechaDescarga == null ? null : DateTime.parse(fechaDescarga),
    );
  }
}
