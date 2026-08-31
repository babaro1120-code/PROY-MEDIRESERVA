import 'weather_snapshot.dart';

class ContextSnapshot {
  const ContextSnapshot({
    required this.latitude,
    required this.longitude,
    required this.weather,
    required this.source,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final WeatherSnapshot weather;
  final String source;
  final DateTime capturedAt;

  Map<String, dynamic> toDatabaseMap() {
    return <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'temperature_c': weather.temperatureC,
      'weather_code': weather.weatherCode,
      'weather_summary': weather.summary,
      'context_source': source,
      'context_captured_at': capturedAt.toUtc().toIso8601String(),
    };
  }

  static ContextSnapshot? tryFromDatabase(Map<String, dynamic> map) {
    final latitude = (map['latitude'] as num?)?.toDouble();
    final longitude = (map['longitude'] as num?)?.toDouble();
    final temperature = (map['temperature_c'] as num?)?.toDouble();
    final weatherCode = (map['weather_code'] as num?)?.toInt();
    final summary = map['weather_summary']?.toString();

    if (latitude == null ||
        longitude == null ||
        temperature == null ||
        weatherCode == null ||
        summary == null) {
      return null;
    }

    return ContextSnapshot(
      latitude: latitude,
      longitude: longitude,
      weather: WeatherSnapshot(
        temperatureC: temperature,
        weatherCode: weatherCode,
        summary: summary,
      ),
      source: map['context_source']?.toString() ?? 'desconocido',
      capturedAt:
          DateTime.tryParse(map['context_captured_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
