import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/weather_code.dart';
import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../viewmodels/search_view_model.dart';
import '../viewmodels/view_state.dart';
import '../viewmodels/weather_view_model.dart';
import 'search_screen.dart';
import 'widgets/message_view.dart';

/// Screen 1: Home / Weather Screen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    SearchViewModel search,
    LocationModel location,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final isNowFavorite = await search.toggleFavorite(location);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isNowFavorite
              ? '${location.name} ditambahkan ke favorit'
              : '${location.name} dihapus dari favorit',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WeatherViewModel>();
    final search = context.watch<SearchViewModel>();
    final location = vm.location;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuaca'),
        actions: [
          if (location != null)
            IconButton(
              tooltip: search.isFavorite(location)
                  ? 'Hapus dari favorit'
                  : 'Simpan ke favorit',
              icon: Icon(
                search.isFavorite(location)
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
              onPressed: () => _toggleFavorite(context, search, location),
            ),
          IconButton(
            tooltip: 'Cari kota',
            icon: const Icon(Icons.search),
            onPressed: () => _openSearch(context),
          ),
        ],
      ),
      body: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, WeatherViewModel vm) {
    switch (vm.state) {
      case ViewState.initial:
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.error:
        return MessageView(
          icon: Icons.cloud_off,
          title: 'Gagal memuat data cuaca',
          message: vm.errorMessage,
          actionLabel: 'Coba lagi',
          onAction: vm.retry,
        );
      case ViewState.empty:
        return MessageView(
          icon: Icons.search_off,
          title: 'Data cuaca kosong',
          message: 'Server tidak mengirim data untuk lokasi ini. '
              'Silakan pilih lokasi lain.',
          actionLabel: 'Cari kota',
          onAction: () => _openSearch(context),
        );
      case ViewState.success:
        final weather = vm.weather;
        final location = vm.location;
        if (weather == null || location == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: vm.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CurrentWeatherCard(
                        location: location,
                        weather: weather,
                      ),
                      const SizedBox(height: 16),
                      _DetailGrid(weather: weather),
                      const SizedBox(height: 24),
                      Text(
                        'Perkiraan ${weather.daily.length} hari ke depan',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      _ForecastList(daily: weather.daily),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

/// Kartu utama: nama kota, kondisi, suhu saat ini.
class _CurrentWeatherCard extends StatelessWidget {
  const _CurrentWeatherCard({required this.location, required this.weather});

  final LocationModel location;
  final WeatherModel weather;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = weather.current;
    final info = WeatherCode.fromCode(current.weatherCode);
    final onPrimary = scheme.onPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(
            location.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(color: onPrimary),
          ),
          if (location.subtitle.isNotEmpty)
            Text(
              location.subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: onPrimary),
            ),
          const SizedBox(height: 4),
          Text(
            'Diperbarui ${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(current.time)}',
            style: theme.textTheme.labelMedium?.copyWith(color: onPrimary),
          ),
          const SizedBox(height: 16),
          Icon(info.icon, size: 80, color: onPrimary),
          Text(
            '${current.temperature.round()}°C',
            style: theme.textTheme.displayLarge?.copyWith(color: onPrimary),
          ),
          Text(
            info.description,
            style: theme.textTheme.titleLarge?.copyWith(color: onPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Terasa seperti ${current.apparentTemperature.round()}°C',
            style: theme.textTheme.bodyLarge?.copyWith(color: onPrimary),
          ),
        ],
      ),
    );
  }
}

/// Grid informasi tambahan (responsif: 2 kolom di HP, 3 kolom di layar lebar).
class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.weather});

  final WeatherModel weather;

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final today = weather.daily.isNotEmpty ? weather.daily.first : null;

    final tiles = <_InfoTile>[
      _InfoTile(
        icon: Icons.water_drop_outlined,
        label: 'Kelembapan',
        value: '${current.humidity.round()}%',
      ),
      _InfoTile(
        icon: Icons.air,
        label: 'Kecepatan angin',
        value: '${current.windSpeed.toStringAsFixed(1)} km/j',
      ),
      _InfoTile(
        icon: Icons.umbrella_outlined,
        label: 'Peluang hujan',
        value: '${weather.todayRainProbability.round()}%',
      ),
      _InfoTile(
        icon: Icons.grain,
        label: 'Curah hujan',
        value: '${current.precipitation.toStringAsFixed(1)} mm',
      ),
      _InfoTile(
        icon: Icons.thermostat,
        label: 'Suhu terasa',
        value: '${current.apparentTemperature.round()}°C',
      ),
      _InfoTile(
        icon: Icons.swap_vert,
        label: 'Min / Maks hari ini',
        value: today == null
            ? '-'
            : '${today.minTemp.round()}° / ${today.maxTemp.round()}°',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = constraints.maxWidth >= 600 ? 3 : 2;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles) SizedBox(width: tileWidth, child: tile),
          ],
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 2),
            Text(value, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

/// Daftar perkiraan cuaca harian.
class _ForecastList extends StatelessWidget {
  const _ForecastList({required this.daily});

  final List<DailyForecast> daily;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, d MMM', 'id_ID');

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < daily.length; i++)
            ListTile(
              leading: Icon(
                WeatherCode.fromCode(daily[i].weatherCode).icon,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              title: Text(i == 0 ? 'Hari ini' : dateFormat.format(daily[i].date)),
              subtitle: Text(
                '${WeatherCode.fromCode(daily[i].weatherCode).description} • '
                'Hujan ${daily[i].precipitationProbability.round()}%',
              ),
              trailing: Text(
                '${daily[i].maxTemp.round()}° / ${daily[i].minTemp.round()}°',
                style: theme.textTheme.titleMedium,
              ),
            ),
        ],
      ),
    );
  }
}
