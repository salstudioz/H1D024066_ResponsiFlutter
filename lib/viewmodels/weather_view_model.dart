import 'package:flutter/material.dart';

import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../repositories/weather_repository.dart';
import '../services/api_exception.dart';
import 'view_state.dart';

/// ViewModel untuk Home / Weather Screen.
class WeatherViewModel extends ChangeNotifier {
  WeatherViewModel(this._repository);

  final WeatherRepository _repository;

  /// Lokasi awal jika pengguna belum pernah memilih lokasi.
  static const LocationModel defaultLocation = LocationModel(
    name: 'Jakarta',
    latitude: -6.2146,
    longitude: 106.8451,
    country: 'Indonesia',
    admin1: 'Jakarta',
  );

  ViewState _state = ViewState.initial;
  LocationModel? _location;
  WeatherModel? _weather;
  String _errorMessage = '';
  int _requestId = 0;
  ThemeMode _themeMode = ThemeMode.light;
  bool _isFahrenheit = false;

  ViewState get state => _state;
  LocationModel? get location => _location;
  WeatherModel? get weather => _weather;
  String get errorMessage => _errorMessage;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isFahrenheit => _isFahrenheit;
  String get unitSymbol => _isFahrenheit ? '°F' : '°C';

  /// Konversi suhu dari Celsius ke Fahrenheit jika aktif
  double convertTemp(double celsius) =>
      _isFahrenheit ? (celsius * 9 / 5) + 32 : celsius;

  /// Format teks suhu lengkap: misal "31°C" atau "88°F"
  String formatTemp(double celsius) =>
      '${convertTemp(celsius).round()}°${_isFahrenheit ? 'F' : 'C'}';

  /// Format teks derajat saja: misal "31°"
  String formatDegree(double celsius) => '${convertTemp(celsius).round()}°';

  /// Mengganti tema (Light <-> Dark mode) dan menyimpan ke SharedPreferences.
  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _repository
        .saveThemeMode(_themeMode == ThemeMode.dark ? 'dark' : 'light')
        .ignore();
    notifyListeners();
  }

  /// Mengganti satuan suhu (°C <-> °F) dan menyimpan ke SharedPreferences.
  void toggleUnit() {
    _isFahrenheit = !_isFahrenheit;
    _repository.saveIsFahrenheit(_isFahrenheit).ignore();
    notifyListeners();
  }

  /// Dipanggil saat aplikasi dibuka: tampilkan preferensi tema, satuan, dan lokasi terakhir.
  Future<void> init() async {
    final savedTheme = await _repository.getThemeMode();
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    }

    _isFahrenheit = await _repository.getIsFahrenheit();

    final saved = await _repository.getLastLocation();
    await loadWeather(saved ?? defaultLocation);
  }

  /// Mengambil cuaca dari API untuk [location].
  Future<void> loadWeather(
    LocationModel location, {
    bool showLoading = true,
  }) async {
    final id = ++_requestId;
    _location = location;
    if (showLoading) {
      _state = ViewState.loading;
      notifyListeners();
    }

    try {
      final result = await _repository.getWeather(location);
      if (id != _requestId) return; // ada permintaan yang lebih baru
      _weather = result;
      _state = result.daily.isEmpty ? ViewState.empty : ViewState.success;
      // Simpan lokasi terakhir; kegagalan menyimpan tidak boleh mengganggu UI.
      _repository.saveLastLocation(location).ignore();
    } on ApiException catch (e) {
      if (id != _requestId) return;
      _errorMessage = e.message;
      _state = ViewState.error;
    } catch (_) {
      if (id != _requestId) return;
      _errorMessage = 'Terjadi kesalahan yang tidak terduga';
      _state = ViewState.error;
    }
    notifyListeners();
  }

  /// Tarik-untuk-muat-ulang (tanpa layar loading penuh).
  Future<void> refresh() async {
    final current = _location;
    if (current == null) return;
    await loadWeather(current, showLoading: false);
  }

  /// Tombol "Coba lagi" setelah error.
  Future<void> retry() async {
    final current = _location;
    if (current == null) return;
    await loadWeather(current);
  }
}
