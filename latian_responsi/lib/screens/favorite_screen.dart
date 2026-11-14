import 'package:flutter/material.dart';
import '../models/character.dart';
import '../services/favorite_service.dart';
import 'detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<Character> _favorites = [];
  bool _isLoading = true;

  // Menyimpan key animasi untuk tiap item (digunakan untuk slide-in saat undo)
  final Map<int, GlobalKey<_SlidingCardState>> _cardKeys = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    FavoriteService.favoriteIdsNotifier.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    FavoriteService.favoriteIdsNotifier.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    _loadFavorites(showLoading: false);
  }

  Future<void> _loadFavorites({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    final data = await FavoriteService.getFavorites();

    if (mounted) {
      setState(() {
        _favorites = data;
        _isLoading = false;
      });
    }
  }

  void _removeFavoriteWithUndo(Character char, int index) async {
    // Hapus dari memori lokal agar animasi swipe/klik lancar
    setState(() {
      _favorites.removeAt(index);
      _cardKeys.remove(char.id);
    });

    // Hapus dari SharedPreferences
    await FavoriteService.removeFavorite(char.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${char.name} dihapus dari favorit',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'BATAL',
          textColor: Colors.white,
          onPressed: () async {
            // Tambah kembali ke favorit
            await FavoriteService.addFavorite(char);
            if (!mounted) return;
            // Insert kembali di posisi yang sama (atau di awal jika sudah berubah)
            final insertIndex = index.clamp(0, _favorites.length);
            setState(() {
              _favorites.insert(insertIndex, char);
            });
            // Trigger slide-in animation
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _cardKeys[char.id]?.currentState?.slideIn();
            });
          },
        ),
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }

    if (_favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1C1C1C),
                  border: Border.all(color: Colors.white12, width: 2),
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Daftar Favorit Masih Kosong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tandai karakter favoritmu di Home Screen untuk menyimpannya di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Hint bar
        Container(
          width: double.infinity,
          color: const Color(0xFF1C1C1C),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Row(
            children: [
              Icon(Icons.swipe_left_rounded, size: 16, color: Colors.white38),
              SizedBox(width: 8),
              Text(
                'Swipe atau tekan ikon ❤ untuk menghapus dari favorit',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),

        // List Favorit
        Expanded(
          child: RefreshIndicator(
            color: Colors.white,
            backgroundColor: const Color(0xFF1C1C1C),
            onRefresh: () => _loadFavorites(showLoading: false),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final char = _favorites[index];
                final statusColor = _getStatusColor(char.status);

                // Buat key baru kalau belum ada
                _cardKeys.putIfAbsent(char.id, () => GlobalKey<_SlidingCardState>());
                final cardKey = _cardKeys[char.id]!;

                return Dismissible(
                  key: Key('fav_${char.id}'),
                  direction: DismissDirection.horizontal,
                  background: _buildSwipeBackground(isLeft: true),
                  secondaryBackground: _buildSwipeBackground(isLeft: false),
                  onDismissed: (direction) {
                    _removeFavoriteWithUndo(char, index);
                  },
                  child: _SlidingCard(
                    key: cardKey,
                    child: Card(
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
                            // Foto Karakter
                            Image.network(
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
                            const SizedBox(width: 14),

                            // Data Karakter
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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

                            // Tombol hapus favorit (klik ikon love = unfav)
                            IconButton(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              icon: const Icon(
                                Icons.favorite,
                                color: Colors.redAccent,
                              ),
                              tooltip: 'Hapus dari favorit',
                              onPressed: () => _removeFavoriteWithUndo(char, index),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeBackground({required bool isLeft}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 28),
          SizedBox(width: 8),
          Text(
            'Hapus',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget untuk animasi slide-in dari kiri saat undo
class _SlidingCard extends StatefulWidget {
  final Widget child;

  const _SlidingCard({super.key, required this.child});

  @override
  State<_SlidingCard> createState() => _SlidingCardState();
}

class _SlidingCardState extends State<_SlidingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
      value: 1.0, // mulai dari state sudah selesai (tidak animasi saat pertama load)
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Dipanggil dari luar saat undo untuk trigger animasi slide dari kiri
  void slideIn() {
    _controller.value = 0.0;
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}
