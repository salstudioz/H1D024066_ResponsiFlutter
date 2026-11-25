/// Cuaca saat ini (blok `current` dari Forecast API).
class CurrentWeather {
  const CurrentWeather({
    required this.time,
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed,
  });

  final DateTime time;
  final double temperature;
  final double apparentTemperature;
  final double humidity;
  final double precipitation;
  final int weatherCode;
  final double windSpeed;
}

/// Perkiraan cuaca satu hari (blok `daily` dari Forecast API).
class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.maxTemp,
    required this.minTemp,
    required this.precipitationProbability,
  });

  final DateTime date;
  final int weatherCode;
  final double maxTemp;
  final double minTemp;
  final double precipitationProbability;
}

/// Gabungan data cuaca terkini + perkiraan harian.
class WeatherModel {
  const WeatherModel({
    required this.current,
    required this.daily,
    required this.timezone,
  });

  final CurrentWeather current;
  final List<DailyForecast> daily;
  final String timezone;

  /// Peluang hujan hari ini (dari prakiraan harian pertama).
  double get todayRainProbability =>
      daily.isEmpty ? 0 : daily.first.precipitationProbability;

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final currentJson = json['current'] as Map<String, dynamic>?;
    if (currentJson == null) {
      throw const FormatException('Data cuaca terkini tidak tersedia');
    }
    final dailyJson =
        (json['daily'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    final current = CurrentWeather(
      time: DateTime.parse(currentJson['time'] as String),
      temperature: _toDouble(currentJson['temperature_2m']),
      apparentTemperature: _toDouble(currentJson['apparent_temperature']),
      humidity: _toDouble(currentJson['relative_humidity_2m']),
      precipitation: _toDouble(currentJson['precipitation']),
      weatherCode: _toDouble(currentJson['weather_code']).toInt(),
      windSpeed: _toDouble(currentJson['wind_speed_10m']),
    );

    final times = (dailyJson['time'] as List<dynamic>?) ?? const <dynamic>[];
    final codes =
        (dailyJson['weather_code'] as List<dynamic>?) ?? const <dynamic>[];
    final maxs = (dailyJson['temperature_2m_max'] as List<dynamic>?) ??
        const <dynamic>[];
    final mins = (dailyJson['temperature_2m_min'] as List<dynamic>?) ??
        const <dynamic>[];
    final rains =
        (dailyJson['precipitation_probability_max'] as List<dynamic>?) ??
            const <dynamic>[];

    final daily = <DailyForecast>[];
    for (var i = 0; i < times.length; i++) {
      daily.add(
        DailyForecast(
          date: DateTime.parse(times[i] as String),
          weatherCode: _at(codes, i).toInt(),
          maxTemp: _at(maxs, i),
          minTemp: _at(mins, i),
          precipitationProbability: _at(rains, i),
        ),
      );
    }

    return WeatherModel(
      current: current,
      daily: daily,
      timezone: (json['timezone'] as String?) ?? '',
    );
  }

  static double _toDouble(dynamic value) => (value as num?)?.toDouble() ?? 0;

  static double _at(List<dynamic> list, int index) =>
      index < list.length ? _toDouble(list[index]) : 0;
}
