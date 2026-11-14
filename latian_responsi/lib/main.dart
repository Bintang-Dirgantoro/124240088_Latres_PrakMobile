import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/auth_service.dart';
import 'services/favorite_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Hive Local Database
  await Hive.initFlutter();

  // Inisialisasi Auth & Favorite Service
  await AuthService.init();
  await FavoriteService.init();

  // Cek sesi login tersimpan di SharedPreferences
  final bool isLoggedIn = await AuthService.isLoggedIn();

  runApp(RickAndMortyApp(isLoggedIn: isLoggedIn));
}

class RickAndMortyApp extends StatelessWidget {
  final bool isLoggedIn;

  const RickAndMortyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rick & Morty Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF14171E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF97CE4C),
          secondary: Color(0xFF00B5CC),
          surface: Color(0xFF1E2430),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E2430),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: isLoggedIn ? const MainNavigationScreen() : const LoginScreen(),
    );
  }
}
