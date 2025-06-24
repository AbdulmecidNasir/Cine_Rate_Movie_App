import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_service.dart';
import '../models/movie_model.dart';
import '../widgets/movie_card.dart';
import 'favorites_page.dart';
import 'categories_page.dart';
import 'profile_page.dart';
import '../theme/theme_notifier.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Movie>> popularMovies;
  late Future<List<Movie>> nowPlayingMovies;
  late Future<List<Movie>> topRatedMovies;
  int currentIndex = 0;

  final List<Widget Function()> pages = [
    () => const CategoriesPage(),
    () => const FavoritesPage(),
    () => const ProfilePage(),
  ];

  void _loadMovies() {
    popularMovies = ApiService.fetchPopularMovies();
    nowPlayingMovies = ApiService.fetchNowPlayingMovies();
    topRatedMovies = ApiService.fetchTopRatedMovies();
  }

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Widget _buildMovieSection(String title, Future<List<Movie>> moviesFuture) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 300,
          child: FutureBuilder<List<Movie>>(
            future: moviesFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final movies = snapshot.data!;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 200,
                      child: MovieCard(movie: movies[index], heroTag: 'movie_poster_${movies[index].id}'),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CineRate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: child.key == const ValueKey('icon1')
                    ? Tween(begin: 1.0, end: 0.75).animate(anim)
                    : Tween(begin: 0.75, end: 1.0).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: IconButton(
                key: ValueKey(themeNotifier.isDarkMode ? 'icon1' : 'icon2'),
                icon: Icon(
                  themeNotifier.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                onPressed: () {
                  themeNotifier.toggleTheme();
                },
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadMovies();
          });
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMovieSection('Popüler Filmler', popularMovies),
              const SizedBox(height: 16),
              _buildMovieSection('Vizyondaki Filmler', nowPlayingMovies),
              const SizedBox(height: 16),
              _buildMovieSection('En İyi Filmler', topRatedMovies),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => pages[index - 1]()),
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Anasayfa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Kategoriler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoriler',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hesabım'),
        ],
      ),
    );
  }
}
