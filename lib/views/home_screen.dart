import 'dart:math' as math;
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
import 'widgets/weather_art.dart';

/// Screen 1: Home / Weather Screen.
/// Desain modern dengan dukungan penuh Light Mode (pastel gradient hero),
/// Dark Mode (obsidian slate + glowing accents), serta toggle satuan suhu (°C/°F).
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: location == null
            ? const Text('Cuaca')
            : InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openSearch(context),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 20,
                        color: isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        location.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.north_east,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
        actions: [
          // Tombol ganti satuan suhu (°C / °F)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: vm.toggleUnit,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E283D)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFDBEAFE),
                ),
              ),
              child: Text(
                vm.unitSymbol,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFF2563EB),
                ),
              ),
            ),
          ),

          // Tombol ganti tema (Light / Dark mode)
          IconButton(
            tooltip: 'Ganti tema',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: vm.toggleTheme,
          ),

          if (location != null)
            IconButton(
              tooltip: search.isFavorite(location)
                  ? 'Hapus dari favorit'
                  : 'Simpan ke favorit',
              icon: Icon(
                search.isFavorite(location)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: search.isFavorite(location)
                    ? const Color(0xFFEF4444)
                    : null,
              ),
              onPressed: () => _toggleFavorite(context, search, location),
            ),

          IconButton(
            tooltip: 'Cari kota',
            icon: const Icon(Icons.search),
            onPressed: () => _openSearch(context),
          ),
          const SizedBox(width: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Kartu Cuaca Utama
                      _HeroWeatherCard(
                        location: location,
                        weather: weather,
                        vm: vm,
                      ),
                      const SizedBox(height: 14),

                      // Banner Insight / Tips Cuaca
                      _WeatherInsightBanner(weather: weather),
                      const SizedBox(height: 16),

                      // 6 Kartu Informasi Tambahan (Grid responsif)
                      _DetailGrid(weather: weather, vm: vm),
                      const SizedBox(height: 24),

                      // Judul Prakiraan 7 Hari
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Perkiraan ${weather.daily.length} hari ke depan',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Daftar Prakiraan 7 Hari
                      _ForecastList(daily: weather.daily, vm: vm),
                      const SizedBox(height: 24),
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

/// Kartu Hero Utama dengan gradien dinamis dan ilustrasi layered art
class _HeroWeatherCard extends StatelessWidget {
  const _HeroWeatherCard({
    required this.location,
    required this.weather,
    required this.vm,
  });

  final LocationModel location;
  final WeatherModel weather;
  final WeatherViewModel vm;

  List<Color> _getGradient(int code, bool isDark) {
    if (isDark) {
      if (code == 0 || code == 1) {
        return const [Color(0xFF131C2E), Color(0xFF1E2C44)];
      } else if (code >= 95) {
        return const [Color(0xFF1A162B), Color(0xFF281E3C)];
      } else if (code >= 51 && code <= 67) {
        return const [Color(0xFF111E2E), Color(0xFF1B2E46)];
      }
      return const [Color(0xFF141C2B), Color(0xFF1F2B3E)];
    } else {
      if (code == 0 || code == 1) {
        return const [Color(0xFFFF753E), Color(0xFFFFA258)];
      } else if (code == 2 || code == 3) {
        return const [Color(0xFF3389F1), Color(0xFF62A9FF)];
      } else if (code >= 95) {
        return const [Color(0xFF4A4468), Color(0xFF6B628E)];
      } else if (code >= 51 && code <= 67) {
        return const [Color(0xFF2E7FD8), Color(0xFF56A6F5)];
      }
      return const [Color(0xFF3389F1), Color(0xFF5EA6FF)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = weather.current;
    final info = WeatherCode.fromCode(current.weatherCode);
    final gradientColors = _getGradient(current.weatherCode, isDark);
    final formattedDate =
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(current.time);
    final updatedTime = DateFormat('HH:mm', 'id_ID').format(current.time);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: isDark ? 0.3 : 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.08))
            : null,
      ),
      child: Stack(
        children: [
          // Ambient light ring
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Baris Atas: Tanggal & Waktu update
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Diperbarui $updatedTime',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Ilustrasi Cuaca Layered Art
                WeatherArtWidget(
                  weatherCode: current.weatherCode,
                  size: 110,
                  isNight: isDark &&
                      (current.time.hour < 6 || current.time.hour >= 18),
                ),
                const SizedBox(height: 8),

                // Suhu Utama Besar
                Text(
                  vm.formatTemp(current.temperature),
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.5,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 10),

                // Badge Kondisi Cuaca
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(info.icon, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        info.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Terasa seperti
                Text(
                  'Terasa seperti ${vm.formatTemp(current.apparentTemperature)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),

                // 4 Pill Metrik Cepat di bagian bawah Hero Card
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _QuickPill(
                        icon: Icons.water_drop,
                        label: 'Lembap',
                        value: '${current.humidity.round()}%',
                      ),
                      _VerticalDivider(),
                      _QuickPill(
                        icon: Icons.air,
                        label: 'Angin',
                        value: '${current.windSpeed.round()} km/j',
                      ),
                      _VerticalDivider(),
                      _QuickPill(
                        icon: Icons.umbrella,
                        label: 'Hujan',
                        value: '${weather.todayRainProbability.round()}%',
                      ),
                      _VerticalDivider(),
                      _QuickPill(
                        icon: Icons.grain,
                        label: 'Presip.',
                        value: '${current.precipitation.toStringAsFixed(1)}mm',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}

class _QuickPill extends StatelessWidget {
  const _QuickPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.85)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Banner tips cuaca (terinspirasi dari referensi: "Take care! Rapidly changing weather!")
class _WeatherInsightBanner extends StatelessWidget {
  const _WeatherInsightBanner({required this.weather});

  final WeatherModel weather;

  @override
  Widget build(BuildContext context) {
    final rainProb = weather.todayRainProbability;
    final temp = weather.current.temperature;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData icon;
    String title;
    String message;
    Color accentColor;

    if (rainProb >= 60) {
      icon = Icons.umbrella;
      title = 'Peluang Hujan Tinggi ($rainProb%)';
      message = 'Siapkan payung atau jas hujan sebelum beraktivitas di luar.';
      accentColor = const Color(0xFF38BDF8);
    } else if (temp >= 32) {
      icon = Icons.wb_sunny;
      title = 'Cuaca Panas Terik ($temp°C)';
      message = 'Jaga hidrasi tubuh dan gunakan tabir surya saat bepergian.';
      accentColor = const Color(0xFFFF9800);
    } else if (weather.current.weatherCode >= 95) {
      icon = Icons.thunderstorm;
      title = 'Peringatan Badai Petir';
      message = 'Hindari ruang terbuka dan berteduhlah di tempat yang aman.';
      accentColor = const Color(0xFFF43F5E);
    } else {
      icon = Icons.sentiment_very_satisfied;
      title = 'Cuaca Cukup Bersahabat';
      message = 'Kondisi cuaca nyaman untuk bepergian dan beraktivitas.';
      accentColor = const Color(0xFF10B981);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172033) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid detail 6 kartu informasi dengan circular meters / modern styling
class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.weather, required this.vm});

  final WeatherModel weather;
  final WeatherViewModel vm;

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final today = weather.daily.isNotEmpty ? weather.daily.first : null;

    final tiles = <_DetailCardData>[
      _DetailCardData(
        icon: Icons.water_drop_outlined,
        label: 'Kelembapan',
        value: '${current.humidity.round()}%',
        subtitle: current.humidity > 70 ? 'Cukup lembap' : 'Normal',
        meterFraction: (current.humidity / 100).clamp(0.0, 1.0),
        accentColor: const Color(0xFF38BDF8),
      ),
      _DetailCardData(
        icon: Icons.air,
        label: 'Kecepatan angin',
        value: '${current.windSpeed.toStringAsFixed(1)} km/j',
        subtitle: current.windSpeed > 20 ? 'Angin kencang' : 'Semilir lembut',
        meterFraction: (current.windSpeed / 50).clamp(0.0, 1.0),
        accentColor: const Color(0xFF34D399),
      ),
      _DetailCardData(
        icon: Icons.umbrella_outlined,
        label: 'Peluang hujan',
        value: '${weather.todayRainProbability.round()}%',
        subtitle: weather.todayRainProbability > 50
            ? 'Potensi tinggi'
            : 'Potensi rendah',
        meterFraction: (weather.todayRainProbability / 100).clamp(0.0, 1.0),
        accentColor: const Color(0xFF60A5FA),
      ),
      _DetailCardData(
        icon: Icons.grain,
        label: 'Curah hujan',
        value: '${current.precipitation.toStringAsFixed(1)} mm',
        subtitle: current.precipitation > 5 ? 'Curah lebat' : 'Ringan',
        meterFraction: (current.precipitation / 20).clamp(0.0, 1.0),
        accentColor: const Color(0xFF818CF8),
      ),
      _DetailCardData(
        icon: Icons.thermostat,
        label: 'Suhu terasa',
        value: vm.formatTemp(current.apparentTemperature),
        subtitle: 'Suhu aktual ${vm.formatTemp(current.temperature)}',
        meterFraction:
            ((current.apparentTemperature - 10) / 35).clamp(0.0, 1.0),
        accentColor: const Color(0xFFFB923C),
      ),
      _DetailCardData(
        icon: Icons.swap_vert,
        label: 'Min / Maks hari ini',
        value: today == null
            ? '-'
            : '${vm.formatDegree(today.minTemp)} / ${vm.formatDegree(today.maxTemp)}',
        subtitle: 'Variasi suhu harian',
        meterFraction: 0.65,
        accentColor: const Color(0xFFA78BFA),
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
            for (final tile in tiles)
              SizedBox(
                width: tileWidth,
                child: _ModernInfoCard(data: tile),
              ),
          ],
        );
      },
    );
  }
}

class _DetailCardData {
  _DetailCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.meterFraction,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final double meterFraction;
  final Color accentColor;
}

class _ModernInfoCard extends StatelessWidget {
  const _ModernInfoCard({required this.data});

  final _DetailCardData data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151C2C) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: data.accentColor, size: 18),
              ),
              // Mini arc meter
              _ArcMeter(
                fraction: data.meterFraction,
                color: data.accentColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? const Color(0xFF64748B)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcMeter extends StatelessWidget {
  const _ArcMeter({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _ArcPainter(
          fraction: fraction,
          color: color,
          trackColor: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  final double fraction;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 3.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    final sweep = 2 * math.pi * fraction.clamp(0.0, 1.0);
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}

/// Daftar perkiraan harian 7 hari bergaya modern capsule
class _ForecastList extends StatelessWidget {
  const _ForecastList({required this.daily, required this.vm});

  final List<DailyForecast> daily;
  final WeatherViewModel vm;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('EEEE, d MMM', 'id_ID');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151C2C) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < daily.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Icon cuaca dalam lingkaran pastel
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF1E283D)
                          : const Color(0xFFF1F5F9),
                    ),
                    child: Icon(
                      WeatherCode.fromCode(daily[i].weatherCode).icon,
                      color: isDark
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Hari & kondisi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i == 0 ? 'Hari ini' : dateFormat.format(daily[i].date),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              WeatherCode.fromCode(daily[i].weatherCode)
                                  .description,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            if (daily[i].precipitationProbability > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38BDF8)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${daily[i].precipitationProbability.round()}%',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Pill Suhu Max / Min
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E283D)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          vm.formatDegree(daily[i].maxTemp),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          ' / ${vm.formatDegree(daily[i].minTemp)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i < daily.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF1F5F9),
              ),
          ],
        ],
      ),
    );
  }
}
