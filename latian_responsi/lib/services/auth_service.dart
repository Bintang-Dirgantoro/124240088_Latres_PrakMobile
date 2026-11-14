import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _usersBoxName = 'usersBox';
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyLoginData = 'loginData';
  static const String _keyUsername = 'currentUsername';
  static const String _keyFullName = 'currentFullName';

  // Inisialisasi Box
  static Future<void> init() async {
    await Hive.openBox(_usersBoxName);
    // Tambahkan default demo user sukuna / sukuna123 jika database belum memiliki user
    final box = Hive.box(_usersBoxName);
    if (!box.containsKey('sukuna')) {
      final defaultUser = AppUser(
        username: 'sukuna',
        password: 'sukuna123',
        fullName: 'the Ryomen Sukuna',
      );
      await box.put('sukuna', defaultUser.toMap());
    }
  }

  // Register ke Local Database (Hive)
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String fullName,
  }) async {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();
    final cleanName = fullName.trim();

    if (cleanUsername.isEmpty || cleanPassword.isEmpty || cleanName.isEmpty) {
      return {'success': false, 'message': 'Semua field wajib diisi!'};
    }

    final box = Hive.box(_usersBoxName);
    if (box.containsKey(cleanUsername)) {
      return {'success': false, 'message': 'Username sudah terdaftar! Gunakan username lain.'};
    }

    final newUser = AppUser(
      username: cleanUsername,
      password: cleanPassword,
      fullName: cleanName,
    );

    await box.put(cleanUsername, newUser.toMap());
    return {'success': true, 'message': 'Registrasi berhasil! Silakan login.'};
  }

  // Login: Cek ke Hive dan simpan session ke SharedPreferences
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    if (cleanUsername.isEmpty || cleanPassword.isEmpty) {
      return {'success': false, 'message': 'Username dan password tidak boleh kosong!'};
    }

    final box = Hive.box(_usersBoxName);
    if (!box.containsKey(cleanUsername)) {
      return {'success': false, 'message': 'User tidak ditemukan! Silakan register.'};
    }

    final userData = Map<dynamic, dynamic>.from(box.get(cleanUsername));
    final appUser = AppUser.fromMap(userData);

    if (appUser.password != cleanPassword) {
      return {'success': false, 'message': 'Password salah!'};
    }

    // Simpan ke SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setBool(_keyLoginData, true);
    await prefs.setString(_keyUsername, appUser.username);
    await prefs.setString(_keyFullName, appUser.fullName);

    return {'success': true, 'message': 'Login berhasil! Selamat datang, ${appUser.fullName}'};
  }

  // Cek Session Auto-login
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? prefs.getBool(_keyLoginData) ?? false;
  }

  // Ambil Info Current User
  static Future<Map<String, String>> getCurrentUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(_keyUsername) ?? 'User',
      'fullName': prefs.getString(_keyFullName) ?? 'Rick & Morty Explorer',
    };
  }

  // Logout: Hapus session dari SharedPreferences
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.setBool(_keyLoginData, false);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyFullName);
  }
}
