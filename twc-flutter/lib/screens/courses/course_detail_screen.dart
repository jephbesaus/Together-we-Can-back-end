import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/media_service.dart';
import '../../widgets/app_loader.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final ApiService _api = Get.find<ApiService>();

  Map<String, dynamic>? _course;
  bool _isLoading = true;
  bool _isEnrolling = false;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/courses/${widget.courseId}');
      if (response['success']) {
        setState(() {
          _course = response['data']['course'];
        });
      } else {
        Get.snackbar(
          'Erreur',
          ApiService.extractErrorMessage(response['error'], fallback: 'Formation introuvable.'),
        );
      }
    } catch (e) {
      print('Error loading course: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _enroll() async {
    setState(() => _isEnrolling = true);
    try {
      final response = await _api.post('/courses/${widget.courseId}/enroll');
      if (response['success']) {
        Get.snackbar('Succès', 'Inscription réussie !');
        _loadCourse();
      } else {
        Get.snackbar(
          'Erreur',
          ApiService.extractErrorMessage(response['error'], fallback: 'Échec de l\'inscription.'),
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
    setState(() => _isEnrolling = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Détails de la formation'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const AppLoadingView(message: 'Chargement de la formation...')
          : _course == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Formation introuvable'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Get.back(),
                        child: const Text('Retour'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                        child: _course!['cover_image'] != null
                            ? CachedNetworkImage(
                                imageUrl: MediaService.resolveUrl(_course!['cover_image'])!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported, size: 48),
                                ),
                              )
                            : Container(
                                height: 200,
                                color: AppConstants.primaryColor.withValues(alpha: 0.15),
                                child: const Icon(
                                  Icons.school_outlined,
                                  size: 64,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _course!['title'] ?? 'Formation',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _course!['level_label'] ?? 'Débutant',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppConstants.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _course!['formatted_duration'] ?? '',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Prix : ${_course!['formatted_price'] ?? 'Gratuit'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_course!['description'] != null &&
                                _course!['description'].toString().isNotEmpty) ...[
                              const Text(
                                'À propos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _course!['description'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            _buildSections(_course!),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: _course == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton(
                  onPressed: _isEnrolling
                      ? null
                      : _course!['is_enrolled'] == true
                          ? () => Get.snackbar('Info', 'Vous êtes déjà inscrit à cette formation.')
                          : _enroll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isEnrolling
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _course!['is_enrolled'] == true
                              ? '✓ Inscrit à la formation'
                              : 'S\'inscrire à la formation',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
    );
  }

  Widget _buildSections(Map<String, dynamic> course) {
    final sections = course['sections'] as List? ?? [];

    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Programme',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...sections.map((section) {
          final lessons = section['lessons'] as List? ?? [];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                section['title'] ?? 'Section',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text('${lessons.length} leçons'),
              children: [
                ...lessons.map((lesson) => ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.play_circle_outline,
                        color: AppConstants.primaryColor,
                      ),
                      title: Text(lesson['title'] ?? 'Leçon'),
                      trailing: Text(
                        lesson['formatted_duration'] ?? '',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    )),
              ],
            ),
          );
        }),
      ],
    );
  }
}
