import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../database/db_helper.dart';
import '../models/movie_model.dart';
import 'login_page.dart';
import 'movie_detail_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? username;
  String? email;
  String? profilePhoto;
  bool _isLoading = false;
  List<Movie> favoriteMovies = [];
  Map<String, dynamic>? profileData;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadUserData();
      loadFavorites();
    });
  }

  Future<void> loadUserData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      
      if (userId != null) {
        profileData = await DBHelper.instance.getProfile(userId);
        if (mounted) {
          setState(() {
            username = prefs.getString('username');
            email = prefs.getString('email');
            profilePhoto = profileData?['profile_photo'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> loadFavorites() async {
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      
      if (userId != null) {
        final movies = await DBHelper.instance.getFavorites(userId);
        if (mounted) {
          setState(() {
            favoriteMovies = movies;
          });
        }
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> logout() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Çıkış yapılırken bir hata oluştu. Lütfen tekrar deneyin.'),
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      // Emülatör için izinleri otomatik olarak ver
      if (Platform.isAndroid) {
        await Permission.photos.request();
        await Permission.storage.request();
        await Permission.camera.request();
      }

      // ImagePicker'ı yeniden başlat
      final ImagePicker picker = ImagePicker();
      
      // Galeriden fotoğraf seç
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isLoading = true);
        
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('userId');
        
        if (userId != null) {
          // Fotoğrafı uygulama dizinine kopyala
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = 'profile_$userId.jpg';
          final savedImage = File('${appDir.path}/$fileName');
          await File(image.path).copy(savedImage.path);
          
          await DBHelper.instance.updateProfilePhoto(userId, savedImage.path);
          await loadUserData();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profil fotoğrafı güncellendi'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Fotoğraf seçme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoading ? null : logout,
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profil Başlığı
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                  backgroundImage: profilePhoto != null
                                      ? FileImage(File(profilePhoto!))
                                      : null,
                                  child: profilePhoto == null
                                      ? Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Theme.of(context).primaryColor,
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          username ?? 'Kullanıcı',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (email != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            email!,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Profil Seçenekleri
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildProfileOption(
                          icon: Icons.person_outline,
                          title: 'Hesap Bilgileri',
                          onTap: () => _showAccountInfo(),
                        ),
                        _buildProfileOption(
                          icon: Icons.favorite_border,
                          title: 'Favori Filmlerim',
                          onTap: () => _showFavorites(),
                        ),
                        _buildProfileOption(
                          icon: Icons.history,
                          title: 'İzleme Geçmişi',
                          onTap: () => _showWatchHistory(),
                        ),
                        _buildProfileOption(
                          icon: Icons.settings_outlined,
                          title: 'Ayarlar',
                          onTap: () => _showSettings(),
                        ),
                        const SizedBox(height: 20),
                        // Çıkış Yap Butonu
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : logout,
                            icon: const Icon(Icons.logout),
                            label: const Text('Çıkış Yap'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showAccountInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hesap Bilgileri',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Kullanıcı Adı', username ?? 'Belirtilmemiş'),
            _buildInfoRow('E-posta', email ?? 'Belirtilmemiş'),
            if (profileData != null) ...[
              _buildInfoRow('Ad Soyad', profileData!['name'] ?? 'Belirtilmemiş'),
              _buildInfoRow('Doğum Tarihi', profileData!['birthDate'] ?? 'Belirtilmemiş'),
            ],
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // Profil düzenleme sayfasına yönlendir
                },
                icon: const Icon(Icons.edit),
                label: const Text('Profili Düzenle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFavorites() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Favori Filmlerim',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${favoriteMovies.length} Film',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: favoriteMovies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz favori filminiz yok',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: favoriteMovies.length,
                      itemBuilder: (context, index) {
                        final movie = favoriteMovies[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              'https://image.tmdb.org/t/p/w200${movie.posterPath}',
                              width: 50,
                              height: 75,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(movie.title),
                          subtitle: Text(movie.releaseDate),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MovieDetailPage(movie: movie),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWatchHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'İzleme Geçmişi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildHistoryItem(
                  'Son İzlenen',
                  'Mission: Impossible - Dead Reckoning',
                  '2 saat önce',
                ),
                _buildHistoryItem(
                  'Devam Eden',
                  'Oppenheimer',
                  '45 dakika kaldı',
                ),
                _buildHistoryItem(
                  'Önerilen',
                  'Inception',
                  'Benzer filmlerinize göre',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      // İzleme geçmişi sayfasına yönlendir
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('Tüm Geçmişi Gör'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ayarlar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSettingItem(
                  Icons.notifications_outlined,
                  'Bildirimler',
                  'Film güncellemeleri ve öneriler',
                  true,
                ),
                _buildSettingItem(
                  Icons.dark_mode_outlined,
                  'Karanlık Mod',
                  'Tema tercihinizi değiştirin',
                  false,
                ),
                _buildSettingItem(
                  Icons.language_outlined,
                  'Dil',
                  'Türkçe',
                  false,
                ),
                _buildSettingItem(
                  Icons.storage_outlined,
                  'Önbellek',
                  'Uygulama verilerini temizle',
                  false,
                ),
                _buildSettingItem(
                  Icons.backup_outlined,
                  'Veritabanı Yedekle',
                  'Veritabanını kopyala',
                  false,
                  onTap: () async {
                    try {
                      setState(() => _isLoading = true);
                      final path = await DBHelper.instance.exportDatabase();
                      if (mounted) {
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Veritabanı başarıyla yedeklendi'),
                                const SizedBox(height: 4),
                                Text(
                                  'Konum: $path',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            duration: const Duration(seconds: 5),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Hata: $e'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      // Ayarları sıfırla
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Ayarları Sıfırla'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Alt kısımda boşluk bırak
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String type, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.movie,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              type,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Film detay sayfasına yönlendir
        },
      ),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle,
    bool hasSwitch, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: hasSwitch
          ? Switch(
              value: true,
              onChanged: (value) {
                // Bildirim ayarını değiştir
              },
            )
          : const Icon(Icons.chevron_right),
      onTap: hasSwitch ? null : onTap ?? () {
        // Ayar sayfasına yönlendir
      },
    );
  }
}
