import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/category_model.dart';
import 'category_movies_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late Future<List<Category>> categories;

  @override
  void initState() {
    super.initState();
    categories = ApiService.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Film Kategorileri'),
        elevation: 0,
      ),
      body: FutureBuilder<List<Category>>(
        future: categories,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final categoryList = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: categoryList.length,
              itemBuilder: (context, index) {
                final category = categoryList[index];
                return _buildCategoryCard(category);
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Kategoriler yüklenirken bir hata oluştu',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        categories = ApiService.fetchCategories();
                      });
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryMoviesPage(category: category),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  _getCategoryIcon(category.name),
                  size: 100,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
