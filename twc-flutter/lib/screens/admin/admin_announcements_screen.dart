import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final ApiService _api = Get.find<ApiService>();
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/announcements');
      if (response['success']) {
        setState(() {
          _announcements = List<Map<String, dynamic>>.from(response['data']['announcements'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading announcements: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _delete(int id) async {
    try {
      await _api.delete('/admin/announcements/$id');
      Get.snackbar('Succès', 'Actualité supprimée.');
      _load();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
  }

  Future<void> _togglePin(Map<String, dynamic> a) async {
    try {
      await _api.put('/admin/announcements/${a['id']}', data: {'is_pinned': !(a['is_pinned'] == true)});
      _load();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    File? pickedImage;
    bool notifyAll = false;
    bool isSaving = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle actualité'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Titre')),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Contenu'),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                if (pickedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Image.file(pickedImage!, height: 100),
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final img = await picker.pickImage(source: ImageSource.gallery);
                    if (img != null) setDialogState(() => pickedImage = File(img.path));
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Ajouter une image'),
                ),
                CheckboxListTile(
                  title: const Text('Notifier tous les utilisateurs'),
                  value: notifyAll,
                  onChanged: (v) => setDialogState(() => notifyAll = v ?? false),
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
                      if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                        Get.snackbar('Erreur', 'Titre et contenu requis.');
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      try {
                        final formData = FormData();
                        formData.fields.add(MapEntry('title', titleController.text.trim()));
                        formData.fields.add(MapEntry('content', contentController.text.trim()));
                        formData.fields.add(MapEntry('notify_all', notifyAll ? '1' : '0'));
                        if (pickedImage != null) {
                          formData.files.add(MapEntry(
                            'image',
                            await MultipartFile.fromFile(pickedImage!.path),
                          ));
                        }
                        final response = await _api.multipart('/admin/announcements', formData);
                        if (response['success']) {
                          Get.back();
                          Get.snackbar('Succès', 'Actualité publiée.');
                          _load();
                        } else {
                          Get.snackbar('Erreur', ApiService.extractErrorMessage(response['error']));
                        }
                      } catch (e) {
                        Get.snackbar('Erreur', 'Erreur réseau.');
                      }
                      setDialogState(() => isSaving = false);
                    },
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Publier'),
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
        title: const Text('Gestion des actualités'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? const Center(child: Text('Aucune actualité'))
              : ListView.builder(
                  itemCount: _announcements.length,
                  itemBuilder: (context, index) {
                    final a = _announcements[index];
                    final isPinned = a['is_pinned'] == true;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(isPinned ? Icons.push_pin : Icons.newspaper,
                            color: isPinned ? AppConstants.primaryColor : null),
                        title: Text(a['title'] ?? ''),
                        subtitle: Text(a['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'pin') _togglePin(a);
                            if (v == 'delete') _delete(a['id']);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'pin', child: Text(isPinned ? 'Désépingler' : 'Épingler')),
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
