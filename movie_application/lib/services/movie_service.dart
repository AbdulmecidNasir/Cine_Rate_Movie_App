import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';

class MovieService {
  static const String _apiKey = 'c2bb03651e6fb97969f7911f3035757e';
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  static Future<List<Movie>> fetchPopularMovies() async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/movie/popular?api_key=$_apiKey&language=tr-TR&page=1',
      ),
    );

    if (response.statusCode == 200) {
      final List results = json.decode(response.body)['results'];
      return results.map((e) => Movie.fromJson(e)).toList();
    } else {
      throw Exception('Film verileri alınamadı!');
    }
  }

  static Future<Movie> getMovieDetails(int movieId) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/movie/$movieId?api_key=$_apiKey&language=tr-TR&append_to_response=videos',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Movie Details Response: $data'); // Debug için
      return Movie.fromJson(data);
    } else {
      throw Exception('Film detayları alınamadı!');
    }
  }
}
