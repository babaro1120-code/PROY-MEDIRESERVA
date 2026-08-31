import 'package:flutter_test/flutter_test.dart';
import 'package:MEDIRESERVA/models/weather_snapshot.dart';

void main() {
  test('convierte JSON de Open-Meteo', () {
    final weather = WeatherSnapshot.fromOpenMeteo(<String, dynamic>{
      'current': <String, dynamic>{'temperature_2m': 23.5, 'weather_code': 2},
    });

    expect(weather.temperatureC, 23.5);
    expect(weather.weatherCode, 2);
    expect(weather.summary, 'Parcialmente nublado');
  });
}
