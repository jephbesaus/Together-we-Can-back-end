import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  static const List<Color> _backgrounds = [
    AppConstants.primaryColor,
    Color(0xFF1877F2),
    Color(0xFFE4405F),
    Color(0xFF111111),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
  ];

  final TextEditingController _textController = TextEditingController();
  Color _selectedColor = _backgrounds.first;
  File? _pickedImage;
  bool _isPosting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _pickedImage = File(img.path));
  }

  Future<void> _publish() async {
    if (_pickedImage == null && _textController.text.trim().isEmpty) {
      Get.snackbar('Erreur', 'Ajoutez du texte ou une image pour votre story.');
      return;
    }

    setState(() => _isPosting = true);

    try {
      final api = Get.find<ApiService>();
      final formData = FormData();
      formData.fields.add(MapEntry('content', _textController.text.trim()));
      formData.fields.add(MapEntry('is_story', '1'));
      formData.fields.add(MapEntry('media_type', _pickedImage != null ? 'image' : 'text'));

      if (_pickedImage != null) {
        formData.files.add(MapEntry('media[]', await MultipartFile.fromFile(_pickedImage!.path)));
      }

      final response = await api.multipart('/posts', formData);

      if (response['success']) {
        Get.back(result: true);
        Get.snackbar('Publié', 'Votre story est en ligne pour 24h !');
      } else {
        Get.snackbar('Erreur', ApiService.extractErrorMessage(response['error']));
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }

    setState(() => _isPosting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pickedImage == null ? _selectedColor : Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Nouvelle story', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _publish,
            child: _isPosting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Publier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_pickedImage != null)
            Positioned.fill(
              child: Image.file(_pickedImage!, fit: BoxFit.cover),
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: TextField(
                controller: _textController,
                maxLines: null,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: 'Tapez votre texte...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_pickedImage == null)
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: _backgrounds.map((color) {
                        final isSelected = color == _selectedColor;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Choisir une image'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
