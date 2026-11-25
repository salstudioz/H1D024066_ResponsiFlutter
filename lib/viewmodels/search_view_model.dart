import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/location_model.dart';
import '../repositories/weather_repository.dart';
import '../services/api_exception.dart';
import 'view_state.dart';

/// ViewModel untuk Search / Location Screen
/// (pencarian kota, favorit, dan riwayat pencarian).
class SearchViewModel extends ChangeNotifier {
  SearchViewModel(this._repository);

  final WeatherRepository _repository;

  static const int _maxHistory = 10;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  ViewState _state = ViewState.initial;
  List<LocationModel> _results = <LocationModel>[];
  List<LocationModel> _favorites = <LocationModel>[];
  List<String> _history = <String>[];
  String _errorMessage = '';
  String _lastQuery = '';

  Timer? _debounce;
  int _requestId = 0;

  ViewState get state => _state;
  List<LocationModel> get results => _results;
  List<LocationModel> get favorites => _favorites;
  List<String> get history => _history;
  String get errorMessage => _errorMessage;
  String get lastQuery => _lastQuery;

  /// Memuat favorit & riwayat dari penyimpanan lokal.
  Future<void> loadLocalData() async {
    _favorites = await _repository.getFavorites();
    _history = await _repository.getHistory();
    notifyListeners();
  }

  /// Mengembalikan layar pencarian ke kondisi awal.
  void reset() {
    _debounce?.cancel();
    _requestId++;
    _results = <LocationModel>[];
    _state = ViewState.initial;
    _lastQuery = '';
    notifyListeners();
  }

  /// Dipanggil setiap teks berubah (dengan debounce 500 ms).
  void onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      _requestId++; // batalkan hasil request yang masih berjalan
      _results = <LocationModel>[];
      _state = ViewState.initial;
      _lastQuery = '';
      notifyListeners();
      return;
    }

    _debounce = Timer(_debounceDuration, () => search(query));
  }

  /// Mencari kota ke Geocoding API.
  Future<void> search(String value) async {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      reset();
      return;
    }

    final id = ++_requestId;
    _lastQuery = query;
    _state = ViewState.loading;
    notifyListeners();

    try {
      final found = await _repository.searchLocations(query);
      if (id != _requestId) return;
      _results = found;
      _state = found.isEmpty ? ViewState.empty : ViewState.success;
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

  // ----- Favorit -----
  bool isFavorite(LocationModel location) =>
      _favorites.any((f) => f.key == location.key);

  /// Menambah/menghapus favorit. Mengembalikan true jika sekarang favorit.
  Future<bool> toggleFavorite(LocationModel location) async {
    final index = _favorites.indexWhere((f) => f.key == location.key);
    final nowFavorite = index < 0;
    if (nowFavorite) {
      _favorites = <LocationModel>[location, ..._favorites];
    } else {
      _favorites = List<LocationModel>.from(_favorites)..removeAt(index);
    }
    notifyListeners();
    await _repository.saveFavorites(_favorites);
    return nowFavorite;
  }

  // ----- Riwayat pencarian -----
  Future<void> addHistory(String query) async {
    final text = query.trim();
    if (text.isEmpty) return;
    final updated = <String>[
      text,
      ..._history.where((h) => h.toLowerCase() != text.toLowerCase()),
    ];
    _history = updated.take(_maxHistory).toList();
    notifyListeners();
    await _repository.saveHistory(_history);
  }

  Future<void> removeHistory(String query) async {
    _history = _history.where((h) => h != query).toList();
    notifyListeners();
    await _repository.saveHistory(_history);
  }

  Future<void> clearHistory() async {
    _history = <String>[];
    notifyListeners();
    await _repository.saveHistory(_history);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
