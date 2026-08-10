import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  final ApiService _api = Get.find<ApiService>();
  List<Map<String, dynamic>> _campaigns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/campaigns/my-campaigns');
      if (response['success']) {
        setState(() {
          _campaigns = List<Map<String, dynamic>>.from(response['data']['campaigns'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading campaigns: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _stopCampaign(int id) async {
    try {
      await _api.post('/campaigns/$id/stop');
      _load();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final linkController = TextEditingController();
    final budgetController = TextEditingController();
    File? pickedImage;
    bool isSaving = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle campagne'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Titre')),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                const SizedBox(height: 12),
                TextField(controller: linkController, decoration: const InputDecoration(labelText: 'Lien de destination')),
                const SizedBox(height: 12),
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Budget (FCFA, débité de votre solde Boost)'),
                ),
                const SizedBox(height: 12),
                if (pickedImage != null)
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: Image.file(pickedImage!, height: 100)),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final img = await picker.pickImage(source: ImageSource.gallery);
                    if (img != null) setDialogState(() => pickedImage = File(img.path));
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Ajouter une image'),
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
                      final budget = double.tryParse(budgetController.text);
                      if (titleController.text.trim().isEmpty || budget == null) {
                        Get.snackbar('Erreur', 'Titre et budget valide requis.');
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      try {
                        final formData = FormData();
                        formData.fields.add(MapEntry('title', titleController.text.trim()));
                        formData.fields.add(MapEntry('description', descController.text.trim()));
                        formData.fields.add(MapEntry('link', linkController.text.trim()));
                        formData.fields.add(MapEntry('budget', budget.toString()));
                        if (pickedImage != null) {
                          formData.files.add(MapEntry('image', await MultipartFile.fromFile(pickedImage!.path)));
                        }
                        final response = await _api.multipart('/campaigns', formData);
                        if (response['success']) {
                          Get.back();
                          Get.snackbar('Succès', 'Campagne créée.');
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
                  : const Text('Lancer'),
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
        title: const Text('📢 Marketing'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _campaigns.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Aucune campagne', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _campaigns.length,
                  itemBuilder: (context, index) {
                    final c = _campaigns[index];
                    final isActive = c['status'] == 'active';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(c['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Terminée',
                                    style: TextStyle(fontSize: 11, color: isActive ? Colors.green : Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('👁 ${c['views_count'] ?? 0} vues', style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 16),
                                Text('🖱 ${c['clicks_count'] ?? 0} clics', style: const TextStyle(fontSize: 12)),
                                const Spacer(),
                                if (isActive)
                                  TextButton(
                                    onPressed: () => _stopCampaign(c['id']),
                                    child: const Text('Arrêter', style: TextStyle(color: Colors.red)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
