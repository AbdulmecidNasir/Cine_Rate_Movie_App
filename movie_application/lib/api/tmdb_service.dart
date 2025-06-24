import 'dart:convert';
import 'package:http/http.dart' as http;

class TMDBService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _apiKey = 'c2bb03651e6fb97969f7911f3035757e'; // TMDB API anahtarınızı buraya ekleyin
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  Future<Map<String, dynamic>> getMovieVideos(int movieId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movie/$movieId/videos?api_key=$_apiKey'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load movie videos');
    }
  }

  String? getTrailerUrl(Map<String, dynamic> videosData) {
    final results = videosData['results'] as List;
    if (results.isEmpty) return null;

    // Önce resmi fragmanı bulmaya çalış
    final trailer = results.firstWhere(
      (video) => video['type'] == 'Trailer' && video['site'] == 'YouTube',
      orElse: () => null,
    );

    if (trailer != null) {
      return 'https://www.youtube.com/watch?v=${trailer['key']}';
    }

    // Resmi fragman yoksa ilk YouTube videosunu kullan
    final youtubeVideo = results.firstWhere(
      (video) => video['site'] == 'YouTube',
      orElse: () => null,
    );

    if (youtubeVideo != null) {
      return 'https://www.youtube.com/watch?v=${youtubeVideo['key']}';
    }

    return null;
  }

  String? getVideoId(String url) {
    final uri = Uri.parse(url);
    final queryParams = uri.queryParameters;
    return queryParams['v'];
  }
} 