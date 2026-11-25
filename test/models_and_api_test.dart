import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weather_app/core/weather_code.dart';
import 'package:weather_app/models/location_model.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/services/api_exception.dart';
import 'package:weather_app/services/weather_api_service.dart';

const String _forecastJson = '''
{
  "timezone": "Asia/Jakarta",
  "current": {
    "time": "2026-11-25T14:15",
    "interval": 900,
    "temperature_2m": 31.4,
    "relative_humidity_2m": 70,
    "apparent_temperature": 36.2,
    "precipitation": 0.2,
    "weather_code": 61,
    "wind_speed_10m": 9.5
  },
  "daily": {
    "time": ["2026-11-25", "2026-11-26"],
    "weather_code": [61, 3],
    "temperature_2m_max": [32.1, 31.0],
    "temperature_2m_min": [24.0, 24.5],
    "precipitation_probability_max": [80, 40]
  }
}
''';

const String _geoJson = '''
{
  "results": [
    {
      "id": 1642911,
      "name": "Jakarta",
      "latitude": -6.21462,
      "longitude": 106.84513,
      "country": "Indonesia",
      "admin1": "Jakarta"
    }
  ]
}
''';

void main() {
  group('Model', () {
    test('WeatherModel.fromJson membaca data current dan daily', () {
      final map = jsonDecode(_forecastJson) as Map<String, dynamic>;
      final weather = WeatherModel.fromJson(map);

      expect(weather.current.temperature, 31.4);
      expect(weather.current.humidity, 70);
      expect(weather.current.weatherCode, 61);
      expect(weather.daily.length, 2);
      expect(weather.daily.first.maxTemp, 32.1);
      expect(weather.todayRainProbability, 80);
      expect(weather.timezone, 'Asia/Jakarta');
    });

    test('LocationModel toJson/fromJson konsisten', () {
      const loc = LocationModel(
        name: 'Bandung',
        latitude: -6.9,
        longitude: 107.6,
        country: 'Indonesia',
        admin1: 'Jawa Barat',
      );
      final copy = LocationModel.fromJson(loc.toJson());
      expect(copy.name, 'Bandung');
      expect(copy.key, loc.key);
      expect(copy.subtitle, 'Jawa Barat, Indonesia');
    });

    test('WeatherCode memetakan kode cuaca', () {
      expect(WeatherCode.fromCode(0).description, 'Cerah');
      expect(WeatherCode.fromCode(95).description, 'Badai petir');
      expect(WeatherCode.fromCode(999).description, 'Tidak diketahui');
    });
  });

  group('WeatherApiService', () {
    test('searchLocations mengurai hasil geocoding', () async {
      final service = WeatherApiService(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.host, 'geocoding-api.open-meteo.com');
          expect(request.url.queryParameters['name'], 'Jakarta');
          return http.Response(_geoJson, 200);
        }),
      );
      final result = await service.searchLocations('Jakarta');
      expect(result.length, 1);
      expect(result.first.name, 'Jakarta');
    });

    test('searchLocations mengembalikan list kosong jika tidak ada hasil',
        () async {
      final service = WeatherApiService(
        client: MockClient(
          (request) async => http.Response('{"generationtime_ms": 0.4}', 200),
        ),
      );
      expect(await service.searchLocations('zzzzzz'), isEmpty);
    });

    test('fetchWeather mengirim parameter yang benar', () async {
      final service = WeatherApiService(
        client: MockClient((request) async {
          expect(request.url.host, 'api.open-meteo.com');
          expect(request.url.queryParameters['timezone'], 'auto');
          expect(request.url.queryParameters['current'],
              contains('temperature_2m'));
          expect(request.url.queryParameters['daily'],
              contains('precipitation_probability_max'));
          return http.Response(_forecastJson, 200);
        }),
      );
      final weather = await service.fetchWeather(-6.2, 106.8);
      expect(weather.current.temperature, 31.4);
    });

    test('status bukan 200 menghasilkan ApiException', () async {
      final service = WeatherApiService(
        client: MockClient((request) async => http.Response('error', 500)),
      );
      expect(
        service.fetchWeather(0, 0),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
