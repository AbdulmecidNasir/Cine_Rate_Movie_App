import 'package:flutter/material.dart';
import '../models/movie_model.dart';
import '../database/db_helper.dart';
import '../api/tmdb_service.dart';
import '../services/movie_service.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MovieDetailPage extends StatefulWidget {
  final Movie movie;
  final String? heroTag;

  const MovieDetailPage({Key? key, required this.movie, this.heroTag}) : super(key: key);

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  bool isFavorite = false;
  String? _trailerUrl;
  bool isLoading = false;
  bool isLoadingDetails = false;
  Movie? detailedMovie;
  final TMDBService _tmdbService = TMDBService();
  YoutubePlayerController? _youtubeController;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    checkFavorite();
    _loadTrailer();
    loadMovieDetails();
  }

  @override
  void dispose() {
    _youtubeController?.close();
    super.dispose();
  }

  Future<void> loadMovieDetails() async {
    setState(() {
      isLoadingDetails = true;
    });

    try {
      final movieDetails = await MovieService.getMovieDetails(widget.movie.id);
      setState(() {
        detailedMovie = movieDetails;
      });
    } catch (e) {
      print('Error loading movie details: $e');
    } finally {
      setState(() {
        isLoadingDetails = false;
      });
    }
  }

  Future<void> _loadTrailer() async {
    try {
      final videosData = await _tmdbService.getMovieVideos(widget.movie.id);
      _trailerUrl = _tmdbService.getTrailerUrl(videosData);
      
      if (_trailerUrl != null && mounted) {
        final videoId = _tmdbService.getVideoId(_trailerUrl!);
        if (videoId != null) {
          _youtubeController = YoutubePlayerController.fromVideoId(
            videoId: videoId,
            params: const YoutubePlayerParams(
              showControls: true,
              showFullscreenButton: true,
              mute: false,
              showVideoAnnotations: false,
            ),
          );
          setState(() {
            _isPlayerReady = true;
          });
        }
      }
    } catch (e) {
      print('Trailer yüklenirken hata oluştu: $e');
    }
  }

  Future<void> _launchTrailer() async {
    if (_trailerUrl != null) {
      final uri = Uri.parse(_trailerUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void checkFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId != null) {
      final fav = await DBHelper.instance.isFavorite(widget.movie.id, userId);
      setState(() {
        isFavorite = fav;
      });
    }
  }

  void toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId != null) {
      if (isFavorite) {
        await DBHelper.instance.removeFavorite(widget.movie.id, userId);
      } else {
        await DBHelper.instance.addFavorite(widget.movie, userId);
      }
      setState(() {
        isFavorite = !isFavorite;
      });
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    final runtime = detailedMovie?.runtime ?? widget.movie.runtime;
    String formattedRuntime;
    
    if (runtime > 0) {
      final hours = runtime ~/ 60;
      final minutes = runtime % 60;
      if (hours > 0) {
        formattedRuntime = '$hours sa $minutes dk';
      } else {
        formattedRuntime = '$minutes dk';
      }
    } else {
      formattedRuntime = 'Bilinmiyor';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 32),
              const SizedBox(height: 4),
              Text(
                widget.movie.voteAverage.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const Text(
                'IMDB Puanı',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey[300],
          ),
          Column(
            children: [
              const Icon(Icons.access_time, color: Colors.blue, size: 32),
              const SizedBox(height: 4),
              Text(
                formattedRuntime,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Text(
                'Süre',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey[300],
          ),
          Column(
            children: [
              const Icon(Icons.calendar_today, color: Colors.green, size: 32),
              const SizedBox(height: 4),
              Text(
                widget.movie.releaseDate.split('-')[0],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Text(
                'Yıl',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.movie.genres.map((genre) {
        return Chip(
          label: Text(
            genre,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          labelStyle: TextStyle(
            color: Theme.of(context).primaryColor,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildTrailerSection() {
    if (!_isPlayerReady || _youtubeController == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Fragman',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: YoutubePlayer(
              controller: _youtubeController!,
              aspectRatio: 16 / 9,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _launchTrailer,
            icon: const Icon(Icons.open_in_new),
            label: const Text('YouTube\'da Aç'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: widget.heroTag ?? 'movie_poster_${widget.movie.id}',
                    child: Image.network(
                      'https://image.tmdb.org/t/p/w500${widget.movie.posterPath}',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                ),
                onPressed: toggleFavorite,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movie.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.headlineMedium?.color,
                          height: 1.3,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildRatingSection(),
                  const SizedBox(height: 24),
                  Text(
                    'Film Bilgileri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineSmall?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.language,
                    'Orijinal Dil: İngilizce',
                  ),
                  _buildInfoRow(
                    Icons.movie,
                    'Tür: ${widget.movie.genres.join(", ")}',
                  ),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Yayın Tarihi: ${widget.movie.releaseDate}',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Türler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineSmall?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildGenreChips(),
                  const SizedBox(height: 24),
                  Text(
                    'Özet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineSmall?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.movie.overview,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTrailerSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
