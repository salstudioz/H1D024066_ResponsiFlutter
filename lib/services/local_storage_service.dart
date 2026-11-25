import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_model.dart';

/// Lapisan penyimpanan lokal (SharedPreferences).
/// Menyimpan: lokasi favorit, riwayat pencarian, dan lokasi terakhir dilihat.
class LocalStorageService {
  static const String _favoritesKey = 'favorite_locations';
  static const String _historyKey = 'search_history';
  static const String _lastLocationKey = 'last_location';

  Future<List<LocationModel>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favoritesKey);
    if (raw == null) return <LocationModel>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <LocationModel>[];
    }
  }

  Future<void> saveFavorites(List<LocationModel> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(favorites.map((e) => e.toJson()).toList());
    await prefs.setString(_favoritesKey, raw);
  }

  Future<List<String>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey) ?? <String>[];
  }

  Future<void> saveHistory(List<String> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, history);
  }

  Future<LocationModel?> loadLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastLocationKey);
    if (raw == null) return null;
    try {
      return LocationModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastLocation(LocationModel location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLocationKey, jsonEncode(location.toJson()));
  }
}
