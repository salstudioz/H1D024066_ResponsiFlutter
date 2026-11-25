import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../services/local_storage_service.dart';
import '../services/weather_api_service.dart';

/// Repository: satu pintu akses data untuk ViewModel
/// (menggabungkan sumber data remote/API dan lokal/SharedPreferences).
class WeatherRepository {
  WeatherRepository({
    WeatherApiService? apiService,
    LocalStorageService? storageService,
  })  : _api = apiService ?? WeatherApiService(),
        _storage = storageService ?? LocalStorageService();

  final WeatherApiService _api;
  final LocalStorageService _storage;

  // ----- Remote (API) -----
  Future<List<LocationModel>> searchLocations(String query) =>
      _api.searchLocations(query);

  Future<WeatherModel> getWeather(LocationModel location) =>
      _api.fetchWeather(location.latitude, location.longitude);

  // ----- Lokal -----
  Future<List<LocationModel>> getFavorites() => _storage.loadFavorites();

  Future<void> saveFavorites(List<LocationModel> favorites) =>
      _storage.saveFavorites(favorites);

  Future<List<String>> getHistory() => _storage.loadHistory();

  Future<void> saveHistory(List<String> history) =>
      _storage.saveHistory(history);

  Future<LocationModel?> getLastLocation() => _storage.loadLastLocation();

  Future<void> saveLastLocation(LocationModel location) =>
      _storage.saveLastLocation(location);
}
