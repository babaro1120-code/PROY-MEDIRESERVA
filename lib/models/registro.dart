import 'context_snapshot.dart';

class Registro {
  const Registro({
    this.id,
    required this.titulo,
    required this.descripcion,
    required this.estado,
    this.createdAt,
    this.contexto,
  });

  final String? id;
  final String titulo;
  final String descripcion;
  final String estado;
  final DateTime? createdAt;
  final ContextSnapshot? contexto;

  factory Registro.fromMap(Map<String, dynamic> map) {
    return Registro(
      id: map['id']?.toString(),
      titulo: map['titulo']?.toString() ?? '',
      descripcion: map['descripcion']?.toString() ?? '',
      estado: map['estado']?.toString() ?? 'activo',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      contexto: ContextSnapshot.tryFromDatabase(map),
    );
  }

  Map<String, dynamic> toInsertMap(String userId) {
    final data = <String, dynamic>{
      'user_id': userId,
      'titulo': titulo.trim(),
      'descripcion': descripcion.trim(),
      'estado': estado,
    };

    if (contexto != null) {
      data.addAll(contexto!.toDatabaseMap());
    }
    return data;
  }

  Map<String, dynamic> toUpdateMap() {
    return <String, dynamic>{
      'titulo': titulo.trim(),
      'descripcion': descripcion.trim(),
      'estado': estado,
      'latitude': contexto?.latitude,
      'longitude': contexto?.longitude,
      'temperature_c': contexto?.weather.temperatureC,
      'weather_code': contexto?.weather.weatherCode,
      'weather_summary': contexto?.weather.summary,
      'context_source': contexto?.source,
      'context_captured_at': contexto?.capturedAt.toUtc().toIso8601String(),
    };
  }

  Registro copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    String? estado,
    DateTime? createdAt,
    ContextSnapshot? contexto,
  }) {
    return Registro(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      contexto: contexto ?? this.contexto,
    );
  }
}
