import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'repositories/weather_repository.dart';
import 'viewmodels/search_view_model.dart';
import 'viewmodels/weather_view_model.dart';
import 'views/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Data format tanggal Bahasa Indonesia (dipakai DateFormat 'id_ID').
  await initializeDateFormatting('id_ID', null);
  runApp(MyApp(repository: WeatherRepository()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.repository});

  final WeatherRepository repository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WeatherViewModel>(
          create: (_) => WeatherViewModel(repository)..init(),
        ),
        ChangeNotifierProvider<SearchViewModel>(
          create: (_) => SearchViewModel(repository)..loadLocalData(),
        ),
      ],
      child: MaterialApp(
        title: 'Aplikasi Cuaca',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
