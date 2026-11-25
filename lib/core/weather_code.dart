import 'package:flutter/material.dart';

/// Deskripsi + ikon untuk satu kode cuaca WMO.
class WeatherInfo {
  const WeatherInfo(this.description, this.icon);

  final String description;
  final IconData icon;
}

/// Menerjemahkan `weather_code` (standar WMO) dari Open-Meteo.
class WeatherCode {
  const WeatherCode._();

  static WeatherInfo fromCode(int code) {
    switch (code) {
      case 0:
        return const WeatherInfo('Cerah', Icons.wb_sunny);
      case 1:
        return const WeatherInfo('Sebagian besar cerah', Icons.wb_sunny);
      case 2:
        return const WeatherInfo('Berawan sebagian', Icons.wb_cloudy);
      case 3:
        return const WeatherInfo('Mendung', Icons.cloud);
      case 45:
      case 48:
        return const WeatherInfo('Berkabut', Icons.blur_on);
      case 51:
      case 53:
      case 55:
        return const WeatherInfo('Gerimis', Icons.grain);
      case 56:
      case 57:
        return const WeatherInfo('Gerimis beku', Icons.grain);
      case 61:
        return const WeatherInfo('Hujan ringan', Icons.water_drop);
      case 63:
        return const WeatherInfo('Hujan sedang', Icons.water_drop);
      case 65:
        return const WeatherInfo('Hujan lebat', Icons.water_drop);
      case 66:
      case 67:
        return const WeatherInfo('Hujan beku', Icons.ac_unit);
      case 71:
      case 73:
      case 75:
        return const WeatherInfo('Salju', Icons.ac_unit);
      case 77:
        return const WeatherInfo('Butiran salju', Icons.ac_unit);
      case 80:
      case 81:
      case 82:
        return const WeatherInfo('Hujan deras sesaat', Icons.umbrella);
      case 85:
      case 86:
        return const WeatherInfo('Hujan salju sesaat', Icons.ac_unit);
      case 95:
        return const WeatherInfo('Badai petir', Icons.thunderstorm);
      case 96:
      case 99:
        return const WeatherInfo('Badai petir disertai es', Icons.thunderstorm);
      default:
        return const WeatherInfo('Tidak diketahui', Icons.help_outline);
    }
  }
}
