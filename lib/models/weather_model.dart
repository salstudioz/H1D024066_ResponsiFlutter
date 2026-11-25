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

/// Perkiraan cuaca per jam (blok `hourly` dari Forecast API).
class HourlyForecast {
  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
  });

  final DateTime time;
  final double temperature;
  final int weatherCode;
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

/// Gabungan data cuaca terkini + perkiraan harian + perkiraan per jam.
class WeatherModel {
  const WeatherModel({
    required this.current,
    required this.daily,
    required this.timezone,
    this.hourly = const <HourlyForecast>[],
  });

  final CurrentWeather current;
  final List<DailyForecast> daily;
  final List<HourlyForecast> hourly;
  final String timezone;

  /// Peluang hujan hari ini (dari prakiraan harian pertama).
  double get todayRainProbability =>
      daily.isEmpty ? 0 : daily.first.precipitationProbability;

  /// Daftar prakiraan 16-24 jam ke depan mulai dari waktu saat ini.
  List<HourlyForecast> get upcomingHourly {
    if (hourly.isEmpty) return const <HourlyForecast>[];
    final now = current.time;
    final threshold = now.subtract(const Duration(minutes: 50));
    final future = hourly.where((h) => h.time.isAfter(threshold)).take(18).toList();
    return future.isNotEmpty ? future : hourly.take(12).toList();
  }

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final currentJson = json['current'] as Map<String, dynamic>?;
    if (currentJson == null) {
      throw const FormatException('Data cuaca terkini tidak tersedia');
    }
    final dailyJson =
        (json['daily'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final hourlyJson =
        (json['hourly'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    final current = CurrentWeather(
      time: DateTime.parse(currentJson['time'] as String),
      temperature: _toDouble(currentJson['temperature_2m']),
      apparentTemperature: _toDouble(currentJson['apparent_temperature']),
      humidity: _toDouble(currentJson['relative_humidity_2m']),
      precipitation: _toDouble(currentJson['precipitation']),
      weatherCode: _toDouble(currentJson['weather_code']).toInt(),
      windSpeed: _toDouble(currentJson['wind_speed_10m']),
    );

    // Parse Daily
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

    // Parse Hourly
    final hTimes = (hourlyJson['time'] as List<dynamic>?) ?? const <dynamic>[];
    final hTemps =
        (hourlyJson['temperature_2m'] as List<dynamic>?) ?? const <dynamic>[];
    final hCodes =
        (hourlyJson['weather_code'] as List<dynamic>?) ?? const <dynamic>[];

    final hourly = <HourlyForecast>[];
    for (var i = 0; i < hTimes.length; i++) {
      hourly.add(
        HourlyForecast(
          time: DateTime.parse(hTimes[i] as String),
          temperature: _at(hTemps, i),
          weatherCode: _at(hCodes, i).toInt(),
        ),
      );
    }

    return WeatherModel(
      current: current,
      daily: daily,
      hourly: hourly,
      timezone: (json['timezone'] as String?) ?? '',
    );
  }

  static double _toDouble(dynamic value) => (value as num?)?.toDouble() ?? 0;

  static double _at(List<dynamic> list, int index) =>
      index < list.length ? _toDouble(list[index]) : 0;
}
