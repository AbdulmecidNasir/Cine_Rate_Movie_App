import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/movie_model.dart';
import 'dart:convert';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('movie_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        email TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        movie_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        overview TEXT,
        poster_path TEXT,
        release_date TEXT,
        vote_average REAL,
        genres TEXT,
        runtime INTEGER,
        added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(user_id, movie_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT,
        birth_date TEXT,
        bio TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Tüm tabloları sil
      await db.execute('DROP TABLE IF EXISTS favorites');
      await db.execute('DROP TABLE IF EXISTS profile');
      await db.execute('DROP TABLE IF EXISTS users');
      
      // Yeni tabloları oluştur
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          email TEXT NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await db.execute('''
        CREATE TABLE favorites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          movie_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          overview TEXT,
          poster_path TEXT,
          release_date TEXT,
          vote_average REAL,
          genres TEXT,
          runtime INTEGER,
          added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          UNIQUE(user_id, movie_id)
        )
      ''');

      await db.execute('''
        CREATE TABLE profile (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT,
          birth_date TEXT,
          bio TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // Kullanıcı işlemleri
  Future<int> registerUser(String username, String password, String email) async {
    final db = await database;
    try {
      return await db.insert('users', {
        'username': username,
        'password': password,
        'email': email,
      });
    } catch (e) {
      print('Error registering user: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    final db = await database;
    try {
      final result = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Error logging in: $e');
      rethrow;
    }
  }

  // Favori işlemleri - kullanıcıya özel
  Future<void> addFavorite(Movie movie, int userId) async {
    try {
      final db = await database;
      
      final existing = await db.query(
        'favorites',
        where: 'movie_id = ? AND user_id = ?',
        whereArgs: [movie.id, userId],
      );

      if (existing.isEmpty) {
        await db.insert('favorites', {
          'movie_id': movie.id,
          'user_id': userId,
          'title': movie.title,
          'overview': movie.overview,
          'poster_path': movie.posterPath,
          'release_date': movie.releaseDate,
          'vote_average': movie.voteAverage,
          'genres': movie.genres.join(','),
          'runtime': movie.runtime,
        });
      }
    } catch (e) {
      print('Error adding favorite: $e');
      rethrow;
    }
  }

  Future<void> removeFavorite(int movieId, int userId) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'movie_id = ? AND user_id = ?',
      whereArgs: [movieId, userId],
    );
  }

  Future<List<Movie>> getFavorites(int userId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return result.map((json) => Movie(
      id: json['movie_id'] as int,
      title: json['title'] as String,
      overview: json['overview'] as String,
      posterPath: json['poster_path'] as String,
      releaseDate: json['release_date'] as String,
      voteAverage: (json['vote_average'] as num).toDouble(),
      genres: (json['genres'] as String).split(','),
      runtime: json['runtime'] as int,
    )).toList();
  }

  Future<bool> isFavorite(int movieId, int userId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'movie_id = ? AND user_id = ?',
      whereArgs: [movieId, userId],
    );
    return result.isNotEmpty;
  }

  // Profil işlemleri - kullanıcıya özel
  Future<void> saveProfile(String name, String birthDate, String imagePath, int userId) async {
    final db = await database;
    await db.delete('profile', where: 'user_id = ?', whereArgs: [userId]);
    await db.insert('profile', {
      'user_id': userId,
      'name': name,
      'birth_date': birthDate,
      'imagePath': imagePath,
    });
  }

  Future<Map<String, dynamic>?> getProfile(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<void> clearProfile() async {
    final db = await database;
    await db.delete('profile');
  }

  Future<void> updateProfilePhoto(int userId, String photoUrl) async {
    final db = await database;
    await db.update(
      'users',
      {'profile_photo': photoUrl},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Veritabanını dışa aktarma metodu
  Future<String> exportDatabase() async {
    try {
      final db = await database;
      
      // Veritabanı içeriğini al
      final favorites = await db.query('favorites');
      final profile = await db.query('profile');
      
      // Veritabanı bilgilerini göster
      print('Veritabanı yolu: ${db.path}');
      print('Favori film sayısı: ${favorites.length}');
      print('Profil bilgisi var mı: ${profile.isNotEmpty}');
      
      // Favori filmleri listele
      for (var movie in favorites) {
        print('Film: ${movie['title']} (ID: ${movie['movie_id']})');
      }
      
      // Profil bilgilerini göster
      if (profile.isNotEmpty) {
        print('Profil: ${profile.first}');
      }
      
      return db.path;
    } catch (e) {
      print('Veritabanı dışa aktarma hatası: $e');
      rethrow;
    }
  }

  // Veritabanını JSON olarak dışa aktarma
  Future<String> exportDatabaseAsJson() async {
    try {
      final db = await database;
      
      // Favorileri al
      final favorites = await db.query('favorites');
      // Profili al
      final profile = await db.query('profile');
      
      // JSON formatında veriyi oluştur
      final data = {
        'favorites': favorites,
        'profile': profile.isNotEmpty ? profile.first : null,
        'exportDate': DateTime.now().toIso8601String(),
      };
      
      // Downloads klasörüne kaydet
      final downloadsPath = '/storage/emulated/0/Download/MovieApp';
      final downloadsDir = Directory(downloadsPath);
      
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$downloadsPath/movie_app_$timestamp.json';
      
      // JSON dosyasını oluştur
      final file = File(filePath);
      await file.writeAsString(jsonEncode(data));
      
      print('Veritabanı JSON olarak dışa aktarıldı: $filePath');
      return filePath;
    } catch (e) {
      print('JSON dışa aktarma hatası: $e');
      rethrow;
    }
  }

  // Veritabanını Downloads klasörüne kopyalama
  Future<void> _exportDatabaseToDownloads() async {
    try {
      final db = await database;
      final dbPath = db.path;
      
      // Downloads klasörünü al
      final downloadsPath = '/storage/emulated/0/Download/MovieApp';
      final downloadsDir = Directory(downloadsPath);
      
      // Klasör yoksa oluştur
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      
      // Veritabanını kopyala
      final targetPath = '$downloadsPath/movie_app.db';
      await File(dbPath).copy(targetPath);
      
      print('Veritabanı güncellendi: $targetPath');
    } catch (e) {
      print('Veritabanı dışa aktarma hatası: $e');
    }
  }

  // Veritabanını senkronize etme
  Future<void> _syncDatabase() async {
    try {
      final db = await database;
      
      // Favorileri al
      final favorites = await db.query('favorites');
      
      // SQL komutlarını oluştur
      final sqlCommands = <String>[];
      
      // Tabloyu temizle
      sqlCommands.add('DELETE FROM favorites;');
      
      // Favorileri ekle
      for (var movie in favorites) {
        sqlCommands.add('''
          INSERT INTO favorites (
            id, title, overview, posterPath, releaseDate, 
            voteAverage, genres, runtime
          ) VALUES (
            ${movie['id']},
            '${movie['title']?.toString().replaceAll("'", "''")}',
            '${movie['overview']?.toString().replaceAll("'", "''")}',
            '${movie['poster_path']}',
            '${movie['release_date']}',
            ${movie['vote_average']},
            '${movie['genres']}',
            ${movie['runtime']}
          );
        ''');
      }
      
      // SQL dosyasını oluştur
      final appDir = await getApplicationDocumentsDirectory();
      final sqlPath = '${appDir.path}/movie_app_sync.sql';
      await File(sqlPath).writeAsString(sqlCommands.join('\n'));
      
      print('SQL dosyası oluşturuldu: $sqlPath');
      print('Favori film sayısı: ${favorites.length}');
      for (var movie in favorites) {
        print('Film: ${movie['title']} (ID: ${movie['movie_id']})');
      }
      
      // Veritabanı dosyasını da kopyala
      final dbPath = db.path;
      final syncPath = '${appDir.path}/movie_app_sync.db';
      await File(dbPath).copy(syncPath);
      print('Veritabanı kopyası oluşturuldu: $syncPath');
      
    } catch (e) {
      print('Veritabanı senkronizasyon hatası: $e');
    }
  }
}
