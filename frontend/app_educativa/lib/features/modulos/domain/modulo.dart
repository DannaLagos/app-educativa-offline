import 'dart:convert';

import 'estado_descarga.dart';

class Modulo {
  final String id;
  final String nombre;
  final String area;
  final int grado;
  final String descripcion;
  final int version;
  final bool estaHabilitado;
  final List<String> contenidos;
  final EstadoDescarga estadoDescarga;
  final String? rutaLocal;
  final DateTime? fechaDescarga;
  final int? versionDescargada;

  const Modulo({
    required this.id,
    required this.nombre,
    required this.area,
    required this.grado,
    required this.descripcion,
    required this.version,
    required this.estaHabilitado,
    this.contenidos = const [],
    this.estadoDescarga = EstadoDescarga.noDescargado,
    this.rutaLocal,
    this.fechaDescarga,
    this.versionDescargada,
  });

  bool get estaDescargado => estadoDescarga == EstadoDescarga.descargado;

  // Un módulo deshabilitado no se puede volver a descargar, así que no se avisa.
  bool get tieneActualizacion =>
      estaHabilitado && estaDescargado && (versionDescargada ?? 0) < version;

  String get areaYGrado => '$area · Grado $grado';

  factory Modulo.desdeCatalogo(Map<String, dynamic> json) {
    return Modulo(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      area: json['area'] as String,
      grado: json['grado'] as int,
      descripcion: json['descripcion'] as String,
      version: json['version'] as int,
      estaHabilitado: json['habilitado'] as bool,
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
      'habilitado': estaHabilitado ? 1 : 0,
      'contenidos': jsonEncode(contenidos),
      'estado_descarga': estadoDescarga.valor,
      'ruta_local': rutaLocal,
      'fecha_descarga': fechaDescarga?.toIso8601String(),
      'version_descargada': versionDescargada,
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
      estaHabilitado: map['habilitado'] == 1,
      contenidos: List<String>.from(
        jsonDecode(map['contenidos'] as String? ?? '[]') as List,
      ),
      estadoDescarga: EstadoDescarga.desdeValor(
        map['estado_descarga'] as String?,
      ),
      rutaLocal: map['ruta_local'] as String?,
      fechaDescarga:
          fechaDescarga == null ? null : DateTime.parse(fechaDescarga),
      versionDescargada: map['version_descargada'] as int?,
    );
  }
}
