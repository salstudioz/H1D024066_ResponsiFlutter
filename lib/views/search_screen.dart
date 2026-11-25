import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/location_model.dart';
import '../viewmodels/search_view_model.dart';
import '../viewmodels/view_state.dart';
import '../viewmodels/weather_view_model.dart';
import 'widgets/message_view.dart';

/// Screen 2: Search / Location Screen.
/// Desain modern dengan dukungan Light Mode & Dark Mode,
/// search bar berbentuk pill, kartu favorit, dan chip riwayat pencarian.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset hasil pencarian sebelumnya setelah frame pertama selesai dibangun.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SearchViewModel>().reset();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Memilih lokasi: muat cuaca di Home lalu kembali.
  void _selectLocation(LocationModel location) {
    final searchVm = context.read<SearchViewModel>();
    final weatherVm = context.read<WeatherViewModel>();
    final navigator = Navigator.of(context);

    final typed = _controller.text.trim();
    searchVm.addHistory(typed.isNotEmpty ? typed : location.name);
    weatherVm.loadWeather(location);
    navigator.pop();
  }

  Future<void> _toggleFavorite(LocationModel location) async {
    final messenger = ScaffoldMessenger.of(context);
    final searchVm = context.read<SearchViewModel>();
    final isNowFavorite = await searchVm.toggleFavorite(location);
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

  void _searchFromHistory(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    setState(() {});
    context.read<SearchViewModel>().search(query);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Lokasi'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Pill Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF151C2C) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama kota...',
                      hintStyle: TextStyle(
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF2563EB),
                      ),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus teks',
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _controller.clear();
                                setState(() {});
                                vm.reset();
                              },
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                    onChanged: (value) {
                      setState(() {});
                      vm.onQueryChanged(value);
                    },
                    onSubmitted: vm.search,
                  ),
                ),
              ),

              Expanded(child: _buildContent(vm, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(SearchViewModel vm, bool isDark) {
    switch (vm.state) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.error:
        return MessageView(
          icon: Icons.cloud_off,
          title: 'Pencarian gagal',
          message: vm.errorMessage,
          actionLabel: 'Coba lagi',
          onAction: () => vm.search(_controller.text),
        );
      case ViewState.empty:
        return MessageView(
          icon: Icons.location_off,
          title: 'Kota tidak ditemukan',
          message: 'Tidak ada hasil untuk "${vm.lastQuery}". '
              'Coba periksa ejaan atau gunakan nama kota lain.',
        );
      case ViewState.success:
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: vm.results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _locationCard(vm, vm.results[index], isDark),
        );
      case ViewState.initial:
        return _buildIdle(vm, isDark);
    }
  }

  /// Kondisi awal: tampilkan favorit dan riwayat pencarian.
  Widget _buildIdle(SearchViewModel vm, bool isDark) {
    if (vm.favorites.isEmpty && vm.history.isEmpty) {
      return const MessageView(
        icon: Icons.travel_explore,
        title: 'Cari kota',
        message: 'Ketik minimal 2 huruf nama kota untuk melihat cuacanya. '
            'Simpan kota sebagai favorit dengan ikon bintang.',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Bagian Favorit
        if (vm.favorites.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFFD600), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Lokasi favorit',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          for (final fav in vm.favorites) ...[
            _locationCard(vm, fav, isDark),
            const SizedBox(height: 8),
          ],
        ],

        // Bagian Riwayat Pencarian
        if (vm.history.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Riwayat pencarian',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: const Text('Hapus Riwayat?'),
                        content: const Text(
                            'Seluruh riwayat pencarian kota akan dibersihkan.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              vm.clearHistory();
                            },
                            child: const Text('Hapus',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Hapus semua'),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in vm.history)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _searchFromHistory(item),
                  child: Container(
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF151C2C)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          iconSize: 16,
                          splashRadius: 14,
                          tooltip: 'Hapus dari riwayat',
                          icon: const Icon(Icons.close),
                          onPressed: () => vm.removeHistory(item),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _locationCard(
      SearchViewModel vm, LocationModel location, bool isDark) {
    final isFavorite = vm.isFavorite(location);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151C2C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? const Color(0xFF1E283D)
                : const Color(0xFFEFF6FF),
          ),
          child: Icon(
            Icons.location_city,
            color: isDark
                ? const Color(0xFF60A5FA)
                : const Color(0xFF2563EB),
            size: 20,
          ),
        ),
        title: Text(
          location.name,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        subtitle: location.subtitle.isEmpty
            ? null
            : Text(
                location.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
        trailing: IconButton(
          tooltip: isFavorite ? 'Hapus dari favorit' : 'Simpan ke favorit',
          icon: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite
                ? const Color(0xFFFFD600)
                : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
          ),
          onPressed: () => _toggleFavorite(location),
        ),
        onTap: () => _selectLocation(location),
      ),
    );
  }
}
