import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final ApiService _api = Get.find<ApiService>();
  final TextEditingController _contentController = TextEditingController();
  final List<XFile> _selectedImages = [];
  bool _isPosting = false;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 6) {
          _selectedImages.removeRange(6, _selectedImages.length);
        }
      });
    }
  }

  Future<void> _publish() async {
    final content = _contentController.text.trim();

    if (content.isEmpty && _selectedImages.isEmpty) {
      Get.snackbar('Erreur', 'Ajoutez du texte ou une image.');
      return;
    }

    setState(() => _isPosting = true);

    try {
      final formData = FormData();
      formData.fields.add(MapEntry('content', content));
      formData.fields.add(MapEntry(
        'media_type',
        _selectedImages.isNotEmpty ? 'image' : 'text',
      ));

      for (final image in _selectedImages) {
        formData.files.add(MapEntry(
          'media[]',
          await MultipartFile.fromFile(image.path, filename: image.name),
        ));
      }

      final response = await _api.multipart('/posts', formData);

      if (response['success']) {
        Get.back(result: true);
        Get.snackbar('Publié', 'Votre publication est en ligne !');
      } else {
        Get.snackbar(
          'Erreur',
          ApiService.extractErrorMessage(response['error'], fallback: 'Échec de la publication.'),
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }

    setState(() => _isPosting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Nouvelle publication'),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _publish,
            child: _isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Publier',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Quoi de neuf ?',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_selectedImages[index].path),
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImages.removeAt(index)),
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Ajouter des photos'),
            ),
          ],
        ),
      ),
    );
  }
}
