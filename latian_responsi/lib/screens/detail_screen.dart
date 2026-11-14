import 'package:flutter/material.dart';
import '../models/character.dart';
import '../services/api_service.dart';
import '../services/favorite_service.dart';

class DetailScreen extends StatefulWidget {
  final Character? character;
  final int? characterId;

  const DetailScreen({
    super.key,
    this.character,
    this.characterId,
  }) : assert(character != null || characterId != null, 'Character or characterId must be provided');

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Character? _character;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.character != null) {
      _character = widget.character;
    } else {
      _fetchCharacterDetail();
    }
  }

  void _fetchCharacterDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getCharacterDetail(widget.characterId!);
      if (mounted) {
        setState(() {
          _character = data;
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

  void _toggleFavorite() async {
    if (_character == null) return;

    final isNowFavorite = await FavoriteService.toggleFavorite(_character!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isNowFavorite ? Icons.favorite : Icons.favorite_border,
              color: isNowFavorite ? Colors.redAccent : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isNowFavorite
                    ? 'Karakter berhasil ditambahkan ke favorit'
                    : '${_character!.name} dihapus dari favorit',
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
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        elevation: 0,
        title: Text(
          _character?.name ?? 'Detail Karakter',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_character != null)
            ValueListenableBuilder<Set<int>>(
              valueListenable: FavoriteService.favoriteIdsNotifier,
              builder: (context, favoriteIds, _) {
                final isFav = favoriteIds.contains(_character!.id);
                return IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.redAccent : Colors.white70,
                    size: 28,
                  ),
                  tooltip: isFav ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
                  onPressed: _toggleFavorite,
                );
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: _fetchCharacterDetail,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_character == null) {
      return const Center(
        child: Text('Data tidak ditemukan', style: TextStyle(color: Colors.white)),
      );
    }

    final char = _character!;
    final statusColor = _getStatusColor(char.status);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Image Card
          Container(
            color: const Color(0xFF1C1C1C),
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Hero(
                    tag: 'char_${char.id}',
                    child: ClipOval(
                      child: Image.network(
                        char.image.isNotEmpty ? char.image : 'https://via.placeholder.com/220?text=No+Image',
                        width: 220,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      border: Border.all(color: Colors.white24, width: 3),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            char.status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & ID
                Text(
                  char.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: #${char.id} • ${char.species}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Informasi Karakter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Info Cards Grid
                _buildInfoTile(
                  icon: Icons.fingerprint_rounded,
                  label: 'Status',
                  value: char.status,
                  valueColor: statusColor,
                ),
                _buildInfoTile(
                  icon: Icons.category_rounded,
                  label: 'Spesies',
                  value: char.species,
                ),
                if (char.type.isNotEmpty)
                  _buildInfoTile(
                    icon: Icons.bubble_chart_rounded,
                    label: 'Tipe / Sub-spesies',
                    value: char.type,
                  ),
                _buildInfoTile(
                  icon: Icons.transgender_rounded,
                  label: 'Gender',
                  value: char.gender,
                ),
                _buildInfoTile(
                  icon: Icons.public_rounded,
                  label: 'Asal Karakter (Origin)',
                  value: char.originName,
                ),
                _buildInfoTile(
                  icon: Icons.location_on_rounded,
                  label: 'Lokasi Sekarang (Location)',
                  value: char.locationName,
                ),
                _buildInfoTile(
                  icon: Icons.movie_outlined,
                  label: 'Penampilan Episode',
                  value: '${char.episode.length} Episode',
                ),

                const SizedBox(height: 24),

                // Button Favorite in Detail Page
                ValueListenableBuilder<Set<int>>(
                  valueListenable: FavoriteService.favoriteIdsNotifier,
                  builder: (context, favoriteIds, _) {
                    final isFav = favoriteIds.contains(char.id);
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFav ? Colors.grey[800] : Colors.white,
                          foregroundColor: isFav ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _toggleFavorite,
                        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.redAccent : Colors.black,
                        ),
                        label: Text(
                          isFav ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white54, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.white,
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
