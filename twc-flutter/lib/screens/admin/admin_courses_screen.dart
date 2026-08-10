import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
  final ApiService _api = Get.find<ApiService>();
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/admin/courses');
      if (response['success']) {
        setState(() {
          _courses = List<Map<String, dynamic>>.from(response['data']['courses'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading courses: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _delete(int id) async {
    try {
      await _api.delete('/admin/courses/$id');
      Get.snackbar('Succès', 'Formation supprimée.');
      _load();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
  }

  Future<void> _togglePublish(Map<String, dynamic> course) async {
    try {
      final response = await _api.put('/admin/courses/${course['id']}', data: {
        'is_published': !(course['is_published'] == true),
      });
      if (response['success']) _load();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController(text: '0');
    String level = 'beginner';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle formation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Titre')),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Prix (FCFA, 0 = gratuit)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: level,
                  decoration: const InputDecoration(labelText: 'Niveau'),
                  items: const [
                    DropdownMenuItem(value: 'beginner', child: Text('Débutant')),
                    DropdownMenuItem(value: 'intermediate', child: Text('Intermédiaire')),
                    DropdownMenuItem(value: 'advanced', child: Text('Avancé')),
                    DropdownMenuItem(value: 'expert', child: Text('Expert')),
                  ],
                  onChanged: (v) => setDialogState(() => level = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  Get.snackbar('Erreur', 'Le titre est requis.');
                  return;
                }
                final price = double.tryParse(priceController.text) ?? 0;
                try {
                  final response = await _api.post('/admin/courses', data: {
                    'title': titleController.text.trim(),
                    'description': descController.text.trim(),
                    'level': level,
                    'price': price,
                    'is_free': price == 0,
                  });
                  if (response['success']) {
                    Get.back();
                    Get.snackbar('Succès', 'Formation créée.');
                    _load();
                  } else {
                    Get.snackbar('Erreur', ApiService.extractErrorMessage(response['error']));
                  }
                } catch (e) {
                  Get.snackbar('Erreur', 'Erreur réseau.');
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Gestion des formations'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? const Center(child: Text('Aucune formation'))
              : ListView.builder(
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    final isPublished = course['is_published'] == true;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(course['title'] ?? ''),
                        subtitle: Text(isPublished ? 'Publiée' : 'Brouillon'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'toggle') _togglePublish(course);
                            if (v == 'delete') _delete(course['id']);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'toggle', child: Text(isPublished ? 'Dépublier' : 'Publier')),
                            const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
