import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/movie_model.dart';
import 'movie_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/movie_card.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with SingleTickerProviderStateMixin {
  List<Movie> favoriteMovies = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    loadFavorites();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    
    if (userId != null) {
      final movies = await DBHelper.instance.getFavorites(userId);
      setState(() {
        favoriteMovies = movies;
        _isLoading = false;
      });

      if (favoriteMovies.isNotEmpty) {
        _animationController.forward();
      }
    }
  }

  void confirmRemoveFavorite(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Favoriden Kaldır'),
        content: const Text(
          'Bu filmi favorilerden silmek istediğinize emin misiniz?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getInt('userId');
              if (userId != null) {
                await DBHelper.instance.removeFavorite(id, userId);
                Navigator.pop(context);
                loadFavorites();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Film favorilerden kaldırıldı'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                );
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorilerim'),
        elevation: 0,
        actions: [
          if (favoriteMovies.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Tüm Favorileri Temizle'),
                    content: const Text(
                      'Tüm favori filmlerinizi silmek istediğinize emin misiniz?',
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final userId = prefs.getInt('userId');
                          if (userId != null) {
                            await DBHelper.instance.removeFavorite(0, userId);
                            Navigator.pop(context);
                            loadFavorites();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tüm favoriler temizlendi'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Temizle', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteMovies.isEmpty
              ? _buildEmptyState()
              : _buildFavoritesGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz favori filminiz yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Beğendiğiniz filmleri favorilere ekleyerek\nburada kolayca erişebilirsiniz',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesGrid() {
    // Filmleri id'ye göre benzersizleştir
    final uniqueMovies = {for (var m in favoriteMovies) m.id: m}.values.toList();
    return RefreshIndicator(
      onRefresh: () async {
        loadFavorites();
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: uniqueMovies.length,
          itemBuilder: (context, index) {
            final movie = uniqueMovies[index];
            return MovieCard(movie: movie, heroTag: 'favorites_movie_poster_${movie.id}');
          },
        ),
      ),
    );
  }
}
