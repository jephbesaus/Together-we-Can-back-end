import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/media_service.dart';
import '../../widgets/app_loader.dart';

class SearchCoursesScreen extends StatefulWidget {
  const SearchCoursesScreen({super.key});

  @override
  State<SearchCoursesScreen> createState() => _SearchCoursesScreenState();
}

class _SearchCoursesScreenState extends State<SearchCoursesScreen> {
  final ApiService _api = Get.find<ApiService>();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = false;
  bool _searched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _searched = true;
    });

    try {
      final response = await _api.get('/courses', params: {'q': query});
      if (response['success']) {
        setState(() {
          _courses = List<Map<String, dynamic>>.from(
            response['data']['courses'] ?? [],
          );
        });
      }
    } catch (e) {
      print('Error searching courses: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rechercher une formation'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Titre, catégorie...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  onPressed: _search,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const AppLoadingView(message: 'Recherche en cours...')
                : !_searched
                    ? Center(
                        child: Text(
                          'Tapez un mot-clé pour rechercher.',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : _courses.isEmpty
                        ? Center(
                            child: Text(
                              'Aucune formation trouvée.',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _courses.length,
                            itemBuilder: (context, index) {
                              final course = _courses[index];
                              return _buildCourseCard(course);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Get.toNamed('/course-detail', arguments: course['id'].toString());
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: course['cover_image'] != null
                  ? CachedNetworkImage(
                      imageUrl: MediaService.resolveUrl(course['cover_image'])!,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      width: 90,
                      height: 90,
                      color: AppConstants.primaryColor.withValues(alpha: 0.15),
                      child: const Icon(Icons.school, color: AppConstants.primaryColor),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['title'] ?? 'Formation',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course['formatted_price'] ?? 'Gratuit',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
