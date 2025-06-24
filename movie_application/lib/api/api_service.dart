import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import '../models/movie_model.dart';
import 'dart:async';
import 'dart:math';

class ApiService {
  static const String _apiKey = 'c2bb03651e6fb97969f7911f3035757e';
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxRetries = 3;

  static String getImageUrl(String path) => '$_imageBaseUrl$path';

  static Future<http.Response> _makeRequest(String url, {int retryCount = 0}) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return response;
      } else {
        throw Exception('API yanıt vermedi: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      if (retryCount < _maxRetries) {
        print('Bağlantı hatası, yeniden deneniyor... (${retryCount + 1}/$_maxRetries)');
        await Future.delayed(Duration(seconds: pow(2, retryCount).toInt()));
        return _makeRequest(url, retryCount: retryCount + 1);
      }
      throw Exception('İnternet bağlantısı hatası: $e');
    } catch (e) {
      if (retryCount < _maxRetries) {
        print('Beklenmeyen hata, yeniden deneniyor... (${retryCount + 1}/$_maxRetries)');
        await Future.delayed(Duration(seconds: pow(2, retryCount).toInt()));
        return _makeRequest(url, retryCount: retryCount + 1);
      }
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  static Future<List<Movie>> fetchPopularMovies() async {
    try {
      final response = await _makeRequest(
        '$_baseUrl/movie/popular?api_key=$_apiKey&language=tr-TR&page=1',
      );
      final List results = json.decode(response.body)['results'];
      return results.map((e) => Movie.fromJson(e)).toList();
    } catch (e) {
      print('Popüler filmler alınırken hata: $e');
      rethrow;
    }
  }

  static Future<List<Movie>> fetchNowPlayingMovies() async {
    try {
      final response = await _makeRequest(
        '$_baseUrl/movie/now_playing?api_key=$_apiKey&language=tr-TR&page=1',
      );
      final List results = json.decode(response.body)['results'];
      return results.map((e) => Movie.fromJson(e)).toList();
    } catch (e) {
      print('Vizyondaki filmler alınırken hata: $e');
      rethrow;
    }
  }

  static Future<List<Movie>> fetchTopRatedMovies() async {
    try {
      final response = await _makeRequest(
        '$_baseUrl/movie/top_rated?api_key=$_apiKey&language=tr-TR&page=1',
      );
      final List results = json.decode(response.body)['results'];
      return results.map((e) => Movie.fromJson(e)).toList();
    } catch (e) {
      print('En iyi filmler alınırken hata: $e');
      rethrow;
    }
  }

  // Kategorileri çek
  static Future<List<Category>> fetchCategories() async {
    try {
      final response = await _makeRequest(
        '$_baseUrl/genre/movie/list?api_key=$_apiKey&language=tr-TR',
      );
      final List results = json.decode(response.body)['genres'];
      return results.map((e) => Category.fromJson(e)).toList();
    } catch (e) {
      print('Kategoriler alınırken hata: $e');
      rethrow;
    }
  }

  static Future<List<Movie>> fetchMoviesByCategory(int categoryId, {int page = 1}) async {
    try {
      final response = await _makeRequest(
        '$_baseUrl/discover/movie?api_key=$_apiKey&language=tr-TR&with_genres=$categoryId&page=$page',
      );
      final List results = json.decode(response.body)['results'];
      return results.map((e) => Movie.fromJson(e)).toList();
    } catch (e) {
      print('Kategori filmleri alınırken hata: $e');
      rethrow;
    }
  }

  static Future<Movie> fetchMovieDetails(int movieId) async {
    try {
      final response = await _makeRequest(
        '$_baseUrl/movie/$movieId?api_key=$_apiKey&language=tr-TR',
      );
      return Movie.fromJson(json.decode(response.body));
    } catch (e) {
      print('Film detayları alınırken hata: $e');
      rethrow;
    }
  }

  static Future<String?> fetchMovieTrailer(int movieId) async {
    try {
      final movieResponse = await _makeRequest(
        '$_baseUrl/movie/$movieId?api_key=$_apiKey&language=tr-TR',
      );

      final movieData = json.decode(movieResponse.body);
      final title = movieData['title'] as String;
      print('Film için fragman aranıyor: $title');

      final response = await _makeRequest(
        '$_baseUrl/movie/$movieId/videos?api_key=$_apiKey&language=tr-TR',
      );

      final data = json.decode(response.body);
      final results = data['results'] as List;
      
      if (results.isEmpty) {
        print('Film için video bulunamadı: $title');
        return null;
      }

      print('Film için ${results.length} video bulundu: $title');

      // Önce resmi Türkçe fragmanı ara
      var trailer = results.firstWhere(
        (video) => 
          video['type'] == 'Trailer' && 
          video['site'] == 'YouTube' && 
          video['official'] == true &&
          video['iso_639_1'] == 'tr',
        orElse: () => null,
      );

      // Resmi Türkçe fragman yoksa resmi İngilizce fragmanı ara
      trailer ??= results.firstWhere(
        (video) => 
          video['type'] == 'Trailer' && 
          video['site'] == 'YouTube' && 
          video['official'] == true &&
          video['iso_639_1'] == 'en',
        orElse: () => null,
      );

      // Resmi fragman yoksa herhangi bir Türkçe fragmanı ara
      trailer ??= results.firstWhere(
        (video) => 
          video['type'] == 'Trailer' && 
          video['site'] == 'YouTube' && 
          video['iso_639_1'] == 'tr',
        orElse: () => null,
      );

      // Türkçe fragman yoksa herhangi bir İngilizce fragmanı ara
      trailer ??= results.firstWhere(
        (video) => 
          video['type'] == 'Trailer' && 
          video['site'] == 'YouTube' && 
          video['iso_639_1'] == 'en',
        orElse: () => null,
      );

      // Hiç fragman yoksa ilk fragmanı al
      trailer ??= results.firstWhere(
        (video) => video['type'] == 'Trailer' && video['site'] == 'YouTube',
        orElse: () => null,
      );

      if (trailer != null) {
        print('Film için fragman bulundu $title: ${trailer['key']}');
        return trailer['key'];
      } else {
        print('Film için uygun fragman bulunamadı: $title');
        return null;
      }
    } catch (e) {
      print('Fragman alınırken hata: $e');
      return null;
    }
  }

  static Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/search/movie?api_key=$_apiKey&query=${Uri.encodeComponent(query.trim())}&language=tr-TR'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      
      return results.map((movie) {
        print('Parsing movie data: $movie'); // Debug için
        return Movie.fromJson(movie);
      }).toList();
    } else {
      throw Exception('Failed to search movies');
    }
  }

  static Future<List<Movie>> getPopularMovies() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movie/popular?api_key=$_apiKey&language=tr-TR'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      
      return results.map((movie) => Movie.fromJson(movie)).toList();
    } else {
      throw Exception('Failed to load popular movies');
    }
  }

  static Future<List<Movie>> getTopRatedMovies() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movie/top_rated?api_key=$_apiKey&language=tr-TR'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      
      return results.map((movie) => Movie.fromJson(movie)).toList();
    } else {
      throw Exception('Failed to load top rated movies');
    }
  }

  static Future<List<Movie>> getUpcomingMovies() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movie/upcoming?api_key=$_apiKey&language=tr-TR'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      
      return results.map((movie) => Movie.fromJson(movie)).toList();
    } else {
      throw Exception('Failed to load upcoming movies');
    }
  }
}
