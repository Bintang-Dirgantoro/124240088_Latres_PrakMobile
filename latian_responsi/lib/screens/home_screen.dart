import 'dart:async';
import 'package:flutter/material.dart';
import '../models/character.dart';
import '../services/api_service.dart';
import '../services/favorite_service.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Character> _characters = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'All';
  Timer? _debounceTimer;

  final List<String> _statusOptions = ['All', 'Alive', 'Dead', 'Unknown'];

  @override
  void initState() {
    super.initState();
    _fetchCharacters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCharacters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ApiService.getCharacters(
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        name: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _characters = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchCharacters();
    });
  }

  void _onStatusSelected(String status) {
    if (_selectedStatus == status) return;
    setState(() {
      _selectedStatus = status;
    });
    _fetchCharacters();
  }

  void _toggleFavorite(Character char) async {
    final isNowFav = await FavoriteService.toggleFavorite(char);

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isNowFav ? Icons.favorite : Icons.favorite_border,
              color: isNowFav ? Colors.redAccent : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isNowFav
                    ? 'Karakter berhasil ditambahkan ke favorit'
                    : '${char.name} dihapus dari favorit',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[850],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'alive':
        return const Color(0xFF55CC44);
      case 'dead':
        return const Color(0xFFD63D2E);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search & Filter Header Container
        Container(
          color: const Color(0xFF1C1C1C),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            children: [
              // Search Field
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari karakter (Rick, Morty, dll)...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _fetchCharacters();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF111111),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter Status Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _statusOptions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final status = _statusOptions[index];
                    final isSelected = _selectedStatus == status;
                    return FilterChip(
                      selected: isSelected,
                      label: Text(
                        status,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      backgroundColor: const Color(0xFF111111),
                      selectedColor: Colors.white,
                      checkmarkColor: Colors.black,
                      side: BorderSide(
                        color: isSelected ? Colors.white : Colors.white24,
                      ),
                      onSelected: (_) => _onStatusSelected(status),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Characters List / States
        Expanded(
          child: RefreshIndicator(
            color: Colors.white,
            backgroundColor: const Color(0xFF1C1C1C),
            onRefresh: _fetchCharacters,
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white54),
            SizedBox(height: 16),
            Text('Memuat karakter...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                'Terjadi Kesalahan',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _fetchCharacters,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_characters.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Tidak Ada Karakter Ditemukan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Coba ubah kata kunci pencarian atau filter status.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _characters.length,
      itemBuilder: (context, index) {
        final char = _characters[index];
        final statusColor = _getStatusColor(char.status);

        return Card(
          color: const Color(0xFF1C1C1C),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white10),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(character: char),
                ),
              );
            },
            child: Row(
              children: [
                // Avatar Karakter
                Hero(
                  tag: 'char_${char.id}',
                  child: Image.network(
                    char.image.isNotEmpty ? char.image : 'https://via.placeholder.com/150?text=No+Image',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Colors.white54,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Info Karakter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        char.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        char.species,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),

                      // Status Badge
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            char.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tombol Favorit
                ValueListenableBuilder<Set<int>>(
                  valueListenable: FavoriteService.favoriteIdsNotifier,
                  builder: (context, favoriteIds, _) {
                    final isFav = favoriteIds.contains(char.id);
                    return IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.redAccent : Colors.white38,
                      ),
                      onPressed: () => _toggleFavorite(char),
                      tooltip: isFav ? 'Hapus dari favorit' : 'Tambah ke favorit',
                    );
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}
