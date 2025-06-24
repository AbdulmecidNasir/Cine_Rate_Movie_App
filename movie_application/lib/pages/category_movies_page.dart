import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/movie_model.dart';
import '../models/category_model.dart';
import '../widgets/movie_card.dart';

class CategoryMoviesPage extends StatefulWidget {
  final Category category;

  const CategoryMoviesPage({super.key, required this.category});

  @override
  State<CategoryMoviesPage> createState() => _CategoryMoviesPageState();
}

class _CategoryMoviesPageState extends State<CategoryMoviesPage> {
  late Future<List<Movie>> movies;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    movies = ApiService.fetchMoviesByCategory(widget.category.id, page: _currentPage);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreMovies();
    }
  }

  Future<void> _loadMoreMovies() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final newMovies = await ApiService.fetchMoviesByCategory(widget.category.id, page: nextPage);
      
      setState(() {
        _currentPage = nextPage;
        movies = Future.value([...movies as List<Movie>, ...newMovies]);
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(widget.category.name),
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: Implement search functionality
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${widget.category.name} Filmleri',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          FutureBuilder<List<Movie>>(
            future: movies,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final movieList = snapshot.data!;
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == movieList.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return MovieCard(movie: movieList[index], heroTag: 'movie_poster_${movieList[index].id}');
                      },
                      childCount: movieList.length + (_isLoadingMore ? 1 : 0),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Filmler yüklenirken bir hata oluştu',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              movies = ApiService.fetchMoviesByCategory(widget.category.id, page: _currentPage);
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'aksiyon':
        return Icons.local_fire_department;
      case 'macera':
        return Icons.terrain;
      case 'animasyon':
        return Icons.animation;
      case 'komedi':
        return Icons.sentiment_very_satisfied;
      case 'suç':
        return Icons.gavel;
      case 'belgesel':
        return Icons.camera_alt;
      case 'dram':
        return Icons.theater_comedy;
      case 'aile':
        return Icons.family_restroom;
      case 'fantastik':
        return Icons.auto_awesome;
      case 'tarih':
        return Icons.history;
      case 'korku':
        return Icons.nightlight_round;
      case 'müzik':
        return Icons.music_note;
      case 'gizem':
        return Icons.psychology;
      case 'romantik':
        return Icons.favorite;
      case 'bilim kurgu':
        return Icons.rocket;
      case 'gerilim':
        return Icons.movie_filter;
      case 'savaş':
        return Icons.security;
      case 'western':
        return Icons.landscape;
      default:
        return Icons.movie;
    }
  }
}
