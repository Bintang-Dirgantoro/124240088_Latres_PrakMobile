import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character.dart';

class FavoriteService {
  static const String _keyFavorites = 'favorite_characters_list';

  // ValueNotifier untuk sinkronisasi instan status favorite ke semua screen
  static final ValueNotifier<Set<int>> favoriteIdsNotifier = ValueNotifier<Set<int>>({});

  // Inisialisasi awal sinkronisasi ID favorite
  static Future<void> init() async {
    final favorites = await getFavorites();
    favoriteIdsNotifier.value = favorites.map((c) => c.id).toSet();
  }

  // Mengambil list semua karakter favorite dari SharedPreferences
  static Future<List<Character>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList = prefs.getStringList(_keyFavorites);
      if (jsonList == null || jsonList.isEmpty) {
        return [];
      }
      return jsonList.map((item) {
        final Map<String, dynamic> map = jsonDecode(item);
        return Character.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint('Error getting favorites: $e');
      return [];
    }
  }

  // Cek apakah karakter difavoritkan
  static bool isFavoriteSync(int characterId) {
    return favoriteIdsNotifier.value.contains(characterId);
  }

  static Future<bool> isFavorite(int characterId) async {
    final favorites = await getFavorites();
    return favorites.any((c) => c.id == characterId);
  }

  // Menambahkan karakter ke SharedPreferences
  static Future<bool> addFavorite(Character character) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> currentList = prefs.getStringList(_keyFavorites) ?? [];

      // Cek jika sudah ada
      final exists = currentList.any((item) {
        final map = jsonDecode(item);
        return map['id'] == character.id;
      });

      if (!exists) {
        currentList.add(jsonEncode(character.toJson()));
        await prefs.setStringList(_keyFavorites, currentList);

        // Update notifier
        final updated = Set<int>.from(favoriteIdsNotifier.value)..add(character.id);
        favoriteIdsNotifier.value = updated;
      }
      return true;
    } catch (e) {
      debugPrint('Error adding favorite: $e');
      return false;
    }
  }

  // Menghapus karakter dari SharedPreferences
  static Future<bool> removeFavorite(int characterId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> currentList = prefs.getStringList(_keyFavorites) ?? [];

      currentList.removeWhere((item) {
        final map = jsonDecode(item);
        return map['id'] == characterId;
      });

      await prefs.setStringList(_keyFavorites, currentList);

      // Update notifier
      final updated = Set<int>.from(favoriteIdsNotifier.value)..remove(characterId);
      favoriteIdsNotifier.value = updated;
      return true;
    } catch (e) {
      debugPrint('Error removing favorite: $e');
      return false;
    }
  }

  // Toggle favorite (tambah jika belum, hapus jika sudah)
  // Return true jika baru ditambahkan, false jika dihapus
  static Future<bool> toggleFavorite(Character character) async {
    final isFav = isFavoriteSync(character.id);
    if (isFav) {
      await removeFavorite(character.id);
      return false;
    } else {
      await addFavorite(character);
      return true;
    }
  }
}
