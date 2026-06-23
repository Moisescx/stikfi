import 'package:flutter/material.dart';

class Nota {
  final int? id;
  final String titulo;
  final String contenido;
  final int colorFondo;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final int sincronizado;
  final bool fijada;

  Nota({
    this.id,
    required this.titulo,
    required this.contenido,
    required this.colorFondo,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.sincronizado = 0,
    this.fijada = false,
  });

  // Convierte un objeto Nota en un Map para guardarlo en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'contenido': contenido,
      'colorFondo': colorFondo,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion.toIso8601String(),
      'sincronizado': sincronizado,
      'fijada': fijada ? 1 : 0,
    };
  }

  // Convierte un Map de la Base de Datos en un objeto Nota
  factory Nota.fromMap(Map<String, dynamic> map) {
    return Nota(
      id: map['id'],
      titulo: map['titulo'] ?? '',
      contenido: map['contenido'] ?? '',
      colorFondo: map['colorFondo'] ?? Colors.yellow.toARGB32(),
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      fechaActualizacion: DateTime.parse(map['fechaActualizacion']),
      sincronizado: map['sincronizado'] ?? 0,
      fijada: map['fijada'] == 1,
    );
  }

  Object? operator [](String key) {
    switch (key) {
      case 'id':
        return id;
      case 'titulo':
        return titulo;
      case 'contenido':
      case 'contenido_plano':
        return contenido;
      case 'colorFondo':
        return colorFondo;
      case 'fechaCreacion':
        return fechaCreacion;
      case 'fechaActualizacion':
        return fechaActualizacion;
      case 'sincronizado':
        return sincronizado;
      case 'fijada':
        return fijada;
      default:
        return null;
    }
  }
}
