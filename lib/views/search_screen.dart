import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/location_model.dart';
import '../viewmodels/search_view_model.dart';
import '../viewmodels/view_state.dart';
import '../viewmodels/weather_view_model.dart';
import 'widgets/message_view.dart';

/// Screen 2: Search / Location Screen.
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

    return Scaffold(
      appBar: AppBar(title: const Text('Cari Lokasi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Masukkan nama kota...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus teks',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                          vm.reset();
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onChanged: (value) {
                setState(() {});
                vm.onQueryChanged(value);
              },
              onSubmitted: vm.search,
            ),
          ),
          Expanded(child: _buildContent(vm)),
        ],
      ),
    );
  }

  Widget _buildContent(SearchViewModel vm) {
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
          itemCount: vm.results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => _locationTile(vm, vm.results[index]),
        );
      case ViewState.initial:
        return _buildIdle(vm);
    }
  }

  /// Kondisi awal: tampilkan favorit dan riwayat pencarian.
  Widget _buildIdle(SearchViewModel vm) {
    if (vm.favorites.isEmpty && vm.history.isEmpty) {
      return const MessageView(
        icon: Icons.travel_explore,
        title: 'Cari kota',
        message: 'Ketik minimal 2 huruf nama kota untuk melihat cuacanya. '
            'Simpan kota sebagai favorit dengan ikon bintang.',
      );
    }

    final theme = Theme.of(context);
    return ListView(
      children: [
        if (vm.favorites.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Lokasi favorit', style: theme.textTheme.titleMedium),
          ),
          for (final fav in vm.favorites) _locationTile(vm, fav),
        ],
        if (vm.history.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Riwayat pencarian',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: vm.clearHistory,
                  child: const Text('Hapus semua'),
                ),
              ],
            ),
          ),
          for (final item in vm.history)
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(item),
              trailing: IconButton(
                tooltip: 'Hapus dari riwayat',
                icon: const Icon(Icons.close),
                onPressed: () => vm.removeHistory(item),
              ),
              onTap: () => _searchFromHistory(item),
            ),
        ],
      ],
    );
  }

  Widget _locationTile(SearchViewModel vm, LocationModel location) {
    final isFavorite = vm.isFavorite(location);
    return ListTile(
      leading: const Icon(Icons.location_city),
      title: Text(location.name),
      subtitle: location.subtitle.isEmpty ? null : Text(location.subtitle),
      trailing: IconButton(
        tooltip: isFavorite ? 'Hapus dari favorit' : 'Simpan ke favorit',
        icon: Icon(isFavorite ? Icons.star : Icons.star_border),
        onPressed: () => _toggleFavorite(location),
      ),
      onTap: () => _selectLocation(location),
    );
  }
}
