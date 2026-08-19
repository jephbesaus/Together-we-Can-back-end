import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/media_service.dart';

class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
  final ApiService _api = Get.find<ApiService>();
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{};
      if (_filterStatus != 'all') params['status'] = _filterStatus;
      final response = await _api.get('/admin/courses', params: params);
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

  Future<void> _approve(int id) async {
    try {
      final response = await _api.post('/admin/courses/$id/approve');
      if (response['success']) {
        Get.snackbar('Succès', 'Formation approuvée.');
        _load();
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
  }

  Future<void> _reject(int id) async {
    try {
      final response = await _api.post('/admin/courses/$id/reject');
      if (response['success']) {
        Get.snackbar('Succès', 'Formation rejetée.');
        _load();
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
  }

  Future<void> _delete(int id) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Supprimer cette formation ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _api.delete('/admin/courses/$id');
        Get.snackbar('Succès', 'Formation supprimée.');
        _load();
      } catch (e) {
        Get.snackbar('Erreur', 'Erreur réseau.');
      }
    }
  }

  Future<void> _pickImage(int courseId) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
      if (picked == null) return;
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final response = await _api.uploadFile('/admin/courses/$courseId', File(picked.path), 'cover_image', method: 'POST');
      Get.back();
      if (response != null && response['success'] == true) {
        Get.snackbar('Succès', 'Image mise à jour.');
        _load();
      } else {
        Get.snackbar('Erreur', 'Échec de l\'upload.');
      }
    } catch (e) {
      Get.back();
      Get.snackbar('Erreur', 'Erreur: $e');
    }
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController(text: '0');
    String level = 'beginner';
    File? pickedImage;

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
                  decoration: const InputDecoration(labelText: 'Prix (CDF, 0 = gratuit)'),
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
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
                    if (picked != null) setDialogState(() => pickedImage = File(picked.path));
                  },
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: pickedImage != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(pickedImage!, fit: BoxFit.cover))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.grey[500]),
                              const SizedBox(height: 4),
                              Text('Image de couverture', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            ],
                          ),
                  ),
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
                Get.back();
                try {
                  final response = await _api.post('/admin/courses', data: {
                    'title': titleController.text.trim(),
                    'description': descController.text.trim(),
                    'level': level,
                    'price': price,
                    'is_free': price == 0,
                  });
                  if (response['success'] && response['data']?['course'] != null) {
                    final courseId = response['data']['course']['id'];
                    if (pickedImage != null) {
                      await _api.uploadFile('/admin/courses/$courseId', pickedImage!, 'cover_image', method: 'POST');
                    }
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
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Toutes', 'all'),
                  _filterChip('En attente', 'pending'),
                  _filterChip('Soumises', 'submitted'),
                  _filterChip('Approuvées', 'approved'),
                  _filterChip('Rejetées', 'rejected'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _courses.isEmpty
                    ? const Center(child: Text('Aucune formation'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _courses.length,
                          itemBuilder: (context, index) => _buildCourseCard(_courses[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : null)),
        selected: isSelected,
        selectedColor: AppConstants.primaryColor,
        onSelected: (_) {
          setState(() => _filterStatus = value);
          _load();
        },
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final coverImage = course['cover_image'];
    final status = course['status'] ?? 'pending';
    final statusColor = status == 'approved'
        ? Colors.green
        : status == 'rejected'
            ? Colors.red
            : Colors.orange;
    final price = double.tryParse('${course['price'] ?? 0}') ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          if (coverImage != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: MediaService.resolveUrl(coverImage) ?? coverImage,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 140,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 140,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),
            )
          else
            Container(
              height: 100,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(child: Icon(Icons.school, size: 40, color: AppConstants.primaryColor)),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        course['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status == 'approved' ? 'Approuvée' : status == 'rejected' ? 'Rejetée' : 'En attente',
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Price + level
                Row(
                  children: [
                    Text(
                      price == 0 ? 'Gratuit' : '${NumberFormat('#,##0', 'fr_FR').format(price)} CDF',
                      style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${course['level'] ?? ''}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Action buttons
                Row(
                  children: [
                    _buildActionBtn(Icons.image, 'Image', () => _pickImage(course['id']), color: Colors.blue),
                    const SizedBox(width: 6),
                    if (status != 'approved')
                      _buildActionBtn(Icons.check_circle, 'Approuver', () => _approve(course['id']), color: Colors.green),
                    if (status != 'rejected')
                      _buildActionBtn(Icons.cancel, 'Rejeter', () => _reject(course['id']), color: Colors.red),
                    const Spacer(),
                    _buildActionBtn(Icons.delete, '', () => _delete(course['id']), color: Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: (color ?? Colors.grey).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color ?? Colors.grey),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, color: color ?? Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }
}
