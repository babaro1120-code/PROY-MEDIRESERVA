import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_snapshot.dart';

class WeatherService {
  const WeatherService();

  Future<WeatherSnapshot> fetchCurrent({
    required double latitude,
    required double longitude,
  }) async {
    final uri =
        Uri.https('api.open-meteo.com', '/v1/forecast', <String, String>{
          'latitude': latitude.toStringAsFixed(6),
          'longitude': longitude.toStringAsFixed(6),
          'current': 'temperature_2m,weather_code',
          'timezone': 'auto',
        });

    final response = await http.get(uri).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON inesperado.');
    }

    return WeatherSnapshot.fromOpenMeteo(decoded);
  }
}
