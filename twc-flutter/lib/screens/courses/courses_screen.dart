import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final ApiService _api = Get.find<ApiService>();

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _myCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);

    try {
      final allCourses = await _api.get('/courses');
      final myCourses = await _api.get('/courses/my-courses');

      if (allCourses['success']) {
        setState(() {
          _courses = List<Map<String, dynamic>>.from(
            allCourses['data']['courses'] ?? [],
          );
        });
      }

      if (myCourses['success']) {
        setState(() {
          _myCourses = List<Map<String, dynamic>>.from(
            myCourses['data']['courses'] ?? [],
          );
        });
      }
    } catch (e) {
      print('Error loading courses: $e');
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
        title: const Text('📚 Formations'),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Get.toNamed('/search-courses'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // My courses
                  if (_myCourses.isNotEmpty) ...[
                    const Text(
                      '🎓 Mes formations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._myCourses.map((course) => _buildCourseCard(course)),
                    const SizedBox(height: 16),
                  ],

                  // All courses
                  const Text(
                    '📖 Catalogue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._courses.map((course) => _buildCourseCard(course)),
                ],
              ),
            ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: course['cover_image'] ?? 'https://via.placeholder.com/400x200',
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                height: 150,
                child: const Icon(Icons.image_not_supported, size: 40),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course['title'] ?? 'Formation',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  course['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        course['level_label'] ?? 'Débutant',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      course['formatted_price'] ?? 'Gratuit',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    if (course['is_enrolled'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${course['progress'] ?? 0}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: () {
                        final courseId = course['id'].toString();
                        if (course['is_enrolled'] == true) {
                          Get.toNamed('/course-detail', arguments: courseId);
                        } else {
                          _enrollCourse(courseId);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        course['is_enrolled'] == true ? 'Continuer' : 'S\'inscrire',
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enrollCourse(String courseId) async {
    try {
      final response = await _api.post('/courses/$courseId/enroll');
      if (response['success']) {
        Get.snackbar('Succès', 'Inscription réussie !');
        _loadCourses();
      } else {
        Get.snackbar(
          'Erreur',
          ApiService.extractErrorMessage(response['error'], fallback: 'Échec de l\'inscription.'),
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
  }
}
