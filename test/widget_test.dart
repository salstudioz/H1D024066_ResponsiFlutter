import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:weather_app/main.dart';
import 'package:weather_app/models/location_model.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/repositories/weather_repository.dart';

/// Repository palsu agar widget test tidak memanggil jaringan / storage asli.
class FakeWeatherRepository extends WeatherRepository {
  @override
  Future<WeatherModel> getWeather(LocationModel location) async {
    return WeatherModel(
      current: CurrentWeather(
        time: DateTime(2026, 11, 25, 14, 15),
        temperature: 31.4,
        apparentTemperature: 36.2,
        humidity: 70,
        precipitation: 0.2,
        weatherCode: 61,
        windSpeed: 9.5,
      ),
      daily: [
        DailyForecast(
          date: DateTime(2026, 11, 25),
          weatherCode: 61,
          maxTemp: 32,
          minTemp: 24,
          precipitationProbability: 80,
        ),
        DailyForecast(
          date: DateTime(2026, 11, 26),
          weatherCode: 3,
          maxTemp: 31,
          minTemp: 24,
          precipitationProbability: 40,
        ),
      ],
      timezone: 'Asia/Jakarta',
    );
  }

  @override
  Future<List<LocationModel>> searchLocations(String query) async =>
      <LocationModel>[];

  @override
  Future<List<LocationModel>> getFavorites() async => <LocationModel>[];

  @override
  Future<void> saveFavorites(List<LocationModel> favorites) async {}

  @override
  Future<List<String>> getHistory() async => <String>[];

  @override
  Future<void> saveHistory(List<String> history) async {}

  @override
  Future<LocationModel?> getLastLocation() async => null;

  @override
  Future<void> saveLastLocation(LocationModel location) async {}

  @override
  Future<String?> getThemeMode() async => null;

  @override
  Future<void> saveThemeMode(String mode) async {}

  @override
  Future<bool> getIsFahrenheit() async => false;

  @override
  Future<void> saveIsFahrenheit(bool isFahrenheit) async {}
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets('Home menampilkan cuaca dan bisa membuka layar pencarian',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(repository: FakeWeatherRepository()));
    await tester.pumpAndSettle();

    // Home Screen: kota, suhu, kondisi cuaca.
    expect(find.text('Jakarta'), findsOneWidget);
    expect(find.text('31°C'), findsOneWidget);
    expect(find.text('Hujan ringan'), findsWidgets);

    // Buka Search Screen.
    await tester.tap(find.byTooltip('Cari kota'));
    await tester.pumpAndSettle();
    expect(find.text('Cari Lokasi'), findsOneWidget);
  });
}
