import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/character.dart';
import '../models/episode.dart';

class ApiService {
  static const String baseUrl = 'https://rickandmortyapi.com/api';

  // Ambil list karakter dengan opsi filter status & search nama.
  // Mengambil seluruh halaman (pagination) agar filter "All" benar-benar menampilkan semua karakter,
  // bukan hanya 20 karakter pertama dari halaman 1.
  static Future<List<Character>> getCharacters({
    String? status,
    String? name,
  }) async {
    final allCharacters = <Character>[];
    var currentPage = 1;

    while (true) {
      final queryParams = <String, String>{
        'page': currentPage.toString(),
      };
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        queryParams['status'] = status.toLowerCase();
      }
      if (name != null && name.trim().isNotEmpty) {
        queryParams['name'] = name.trim();
      }

      final uri = Uri.parse('$baseUrl/character').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      try {
        final response = await http.get(uri).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final List results = data['results'] ?? [];
          if (results.isEmpty) break;

          allCharacters.addAll(results.map((item) => Character.fromJson(item)).toList());

          final int totalPages = data['info']?['pages'] ?? 1;
          if (currentPage >= totalPages) break;

          currentPage++;
        } else if (response.statusCode == 404) {
          // Rick and Morty API mengembalikan 404 jika hasil pencarian / filter tidak ditemukan
          break;
        } else {
          throw Exception('Gagal memuat data karakter (Status code: ${response.statusCode})');
        }
      } catch (e) {
        if (e is FormatException) {
          throw Exception('Format data tidak valid');
        }
        rethrow;
      }
    }

    return allCharacters;
  }

  // Ambil detail karakter berdasarkan ID
  static Future<Character> getCharacterDetail(int id) async {
    final uri = Uri.parse('$baseUrl/character/$id');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Character.fromJson(data);
      } else {
        throw Exception('Karakter tidak ditemukan (Status code: ${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Ambil list episode
  static Future<List<Episode>> getEpisodes({int page = 1}) async {
    final uri = Uri.parse('$baseUrl/episode?page=$page');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List results = data['results'] ?? [];
        return results.map((item) => Episode.fromJson(item)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Gagal memuat daftar episode (Status code: ${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }
}
