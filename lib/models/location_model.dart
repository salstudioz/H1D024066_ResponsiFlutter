/// Model lokasi (hasil Geocoding API Open-Meteo / data favorit).
class LocationModel {
  const LocationModel({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country = '',
    this.admin1 = '',
    this.id,
  });

  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final String country;

  /// Provinsi / wilayah administratif tingkat 1.
  final String admin1;

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: (json['id'] as num?)?.toInt(),
      name: (json['name'] as String?) ?? 'Tidak diketahui',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      country: (json['country'] as String?) ?? '',
      admin1: (json['admin1'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'country': country,
        'admin1': admin1,
      };

  /// Kunci unik berdasarkan koordinat (dipakai untuk cek favorit).
  String get key =>
      '${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)}';

  /// Contoh: "Jawa Tengah, Indonesia".
  String get subtitle {
    final parts = [admin1, country].where((e) => e.isNotEmpty);
    return parts.join(', ');
  }
}
