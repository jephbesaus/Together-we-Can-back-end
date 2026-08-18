import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  final ApiService _api = Get.find<ApiService>();
  final _imagePicker = ImagePicker();

  List<Map<String, dynamic>> _newsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/news');
      if (response['success']) {
        setState(() {
          _newsList = List<Map<String, dynamic>>.from(response['data']['news'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading news: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteNews(int id) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Supprimer l\'actualité'),
        content: const Text('Voulez-vous vraiment supprimer cette actualité ?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _api.delete('/admin/news/$id');
      if (response['success']) {
        setState(() => _newsList.removeWhere((n) => n['id'] == id));
        Get.snackbar('Succès', 'Actualité supprimée.');
      } else {
        Get.snackbar('Erreur', ApiService.extractErrorMessage(response['error']));
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de supprimer.');
    }
  }

  void _showNewsForm({Map<String, dynamic>? news}) {
    final titleController = TextEditingController(text: news?['title'] ?? '');
    final contentController = TextEditingController(text: news?['content'] ?? '');
    File? selectedImage;
    bool isPublished = news?['is_published'] ?? true;
    bool isSaving = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(news != null ? 'Modifier l\'actualité' : 'Nouvelle actualité'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Contenu',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                // Image picker
                if (selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(selectedImage!, height: 120, fit: BoxFit.cover),
                  )
                else if (news?['image_url'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      news!['image_url'],
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setDialogState(() => selectedImage = File(picked.path));
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text('Choisir une image'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Publié'),
                  value: isPublished,
                  onChanged: (v) => setDialogState(() => isPublished = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (titleController.text.trim().isEmpty) {
                        Get.snackbar('Erreur', 'Le titre est requis.');
                        return;
                      }
                      if (contentController.text.trim().isEmpty) {
                        Get.snackbar('Erreur', 'Le contenu est requis.');
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      final formData = dio.FormData.fromMap({
                        'title': titleController.text.trim(),
                        'content': contentController.text.trim(),
                        'is_published': isPublished ? 1 : 0,
                        if (selectedImage != null)
                          'image': await dio.MultipartFile.fromFile(
                            selectedImage!.path,
                            filename: selectedImage!.path.split('/').last,
                          ),
                      });

                      try {
                        Map<String, dynamic> response;
                        if (news != null) {
                          response = await _api.multipart('/admin/news/${news['id']}', formData);
                        } else {
                          response = await _api.multipart('/admin/news', formData);
                        }

                        if (response['success']) {
                          Get.back();
                          Get.snackbar('Succès', news != null ? 'Actualité modifiée.' : 'Actualité créée.');
                          _loadNews();
                        } else {
                          setDialogState(() => isSaving = false);
                          Get.snackbar('Erreur', ApiService.extractErrorMessage(response['error']));
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        Get.snackbar('Erreur', 'Erreur réseau.');
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(news != null ? 'Modifier' : 'Créer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Gérer les Actualités'),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadNews),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _newsList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.newspaper, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Aucune actualité'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _showNewsForm(),
                        style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                        child: const Text('Créer la première', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNews,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _newsList.length,
                    itemBuilder: (context, index) {
                      final news = _newsList[index];
                      return Dismissible(
                        key: ValueKey(news['id']),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          _deleteNews(news['id']);
                          return false;
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: news['image_url'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      news['image_url'],
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 56,
                                        height: 56,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image_not_supported, size: 20),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppConstants.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.newspaper, color: AppConstants.primaryColor),
                                  ),
                            title: Text(
                              news['title'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  news['content'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (news['is_published'] == true || news['is_published'] == 1)
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    (news['is_published'] == true || news['is_published'] == 1)
                                        ? 'Publié'
                                        : 'Brouillon',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: (news['is_published'] == true || news['is_published'] == 1)
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showNewsForm(news: news),
                            ),
                            onTap: () => _showNewsForm(news: news),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewsForm(),
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
