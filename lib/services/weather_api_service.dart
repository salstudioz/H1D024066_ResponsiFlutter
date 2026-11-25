import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/location_model.dart';
import '../models/weather_model.dart';
import 'api_exception.dart';

/// Lapisan networking: seluruh HTTP GET ke Open-Meteo ada di sini.
class WeatherApiService {
  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _geocodingHost = 'geocoding-api.open-meteo.com';
  static const String _forecastHost = 'api.open-meteo.com';
  static const Duration _timeout = Duration(seconds: 15);

  /// Geocoding API: mencari kota berdasarkan nama.
  Future<List<LocationModel>> searchLocations(String name) async {
    final uri = Uri.https(_geocodingHost, '/v1/search', {
      'name': name,
      'count': '10',
      'language': 'id',
      'format': 'json',
    });

    final json = await _get(uri);

    // Jika tidak ada hasil, Open-Meteo tidak mengirim key "results".
    final results = json['results'];
    if (results == null) return <LocationModel>[];

    try {
      return (results as List<dynamic>)
          .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const ApiException('Data lokasi dari server tidak dapat diproses');
    }
  }

  /// Forecast API: cuaca terkini + perkiraan 7 hari.
  Future<WeatherModel> fetchWeather(double latitude, double longitude) async {
    final uri = Uri.https(_forecastHost, '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,'
          'precipitation,weather_code,wind_speed_10m',
      'hourly': 'temperature_2m,weather_code',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,'
          'precipitation_probability_max',
      'timezone': 'auto',
      'forecast_days': '7',
    });

    final json = await _get(uri);

    try {
      return WeatherModel.fromJson(json);
    } catch (_) {
      throw const ApiException('Data cuaca dari server tidak dapat diproses');
    }
  }

  /// HTTP GET + decode JSON + penerjemahan error ke pesan yang ramah.
  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode != 200) {
        throw ApiException(
          'Server mengembalikan kode ${response.statusCode}. Coba lagi nanti.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('Format respons server tidak valid');
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Permintaan terlalu lama. Periksa koneksi Anda.');
    } on FormatException {
      throw const ApiException('Respons server tidak dapat dibaca');
    } catch (_) {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  void dispose() => _client.close();
}
