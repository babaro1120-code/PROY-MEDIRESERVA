class WeatherSnapshot {
  const WeatherSnapshot({
    required this.temperatureC,
    required this.weatherCode,
    required this.summary,
  });

  final double temperatureC;
  final int weatherCode;
  final String summary;

  factory WeatherSnapshot.fromOpenMeteo(Map<String, dynamic> json) {
    final rawCurrent = json['current'];
    if (rawCurrent is! Map) {
      throw const FormatException('La API no devolvio el bloque current.');
    }

    final current = Map<String, dynamic>.from(rawCurrent);
    final temperature = (current['temperature_2m'] as num?)?.toDouble();
    final code = (current['weather_code'] as num?)?.toInt();

    if (temperature == null || code == null) {
      throw const FormatException(
        'La respuesta no contiene temperature_2m y weather_code.',
      );
    }

    return WeatherSnapshot(
      temperatureC: temperature,
      weatherCode: code,
      summary: summaryForCode(code),
    );
  }

  static String summaryForCode(int code) {
    if (code == 0) return 'Despejado';
    if (code == 1) return 'Mayormente despejado';
    if (code == 2) return 'Parcialmente nublado';
    if (code == 3) return 'Nublado';
    if (code == 45 || code == 48) return 'Niebla';
    if (<int>[51, 53, 55, 56, 57].contains(code)) return 'Llovizna';
    if (<int>[61, 63, 65, 66, 67].contains(code)) return 'Lluvia';
    if (<int>[71, 73, 75, 77].contains(code)) return 'Nieve';
    if (<int>[80, 81, 82].contains(code)) return 'Chubascos';
    if (<int>[85, 86].contains(code)) return 'Chubascos de nieve';
    if (<int>[95, 96, 99].contains(code)) return 'Tormenta';
    return 'Codigo meteorologico $code';
  }
}
