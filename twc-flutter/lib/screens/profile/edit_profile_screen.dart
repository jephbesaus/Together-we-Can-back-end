import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/models/user.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _api = Get.find<ApiService>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _currentPhotoUrl;
  File? _pickedPhoto;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final response = await _api.get('/user/profile');
      if (response['success']) {
        final user = response['data']['user'];
        _nameController.text = user['name'] ?? '';
        _bioController.text = user['bio'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        _emailController.text = user['email'] ?? '';
        setState(() {
          _currentPhotoUrl = user['profile_photo_url'] ?? user['profile_photo'];
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadPhoto() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppConstants.primaryColor),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined, color: AppConstants.primaryColor),
              title: const Text('Gestionnaire de fichiers'),
              onTap: () => Navigator.pop(context, 'files'),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    String? path;
    String? name;

    if (choice == 'gallery') {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      path = picked.path;
      name = picked.name;
    } else {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.single.path == null) return;
      path = result.files.single.path;
      name = result.files.single.name;
    }

    setState(() {
      _pickedPhoto = File(path!);
      _isUploadingPhoto = true;
    });

    try {
      final formData = FormData();
      formData.files.add(MapEntry(
        'photo',
        await MultipartFile.fromFile(path, filename: name),
      ));

      final response = await _api.multipart('/user/profile-photo', formData);

      if (response['success']) {
        setState(() => _currentPhotoUrl = response['data']['profile_photo']);
        Get.snackbar('Succès', 'Photo de profil mise à jour.');
      } else {
        Get.snackbar(
          'Erreur',
          ApiService.extractErrorMessage(response['error'], fallback: 'Échec de l\'envoi de la photo.'),
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau lors de l\'envoi de la photo.');
    }

    setState(() => _isUploadingPhoto = false);
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      Get.snackbar('Erreur', 'Le nom est obligatoire.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await _api.put('/user/profile', data: {
        'name': name,
        'bio': bio,
        'phone': phone,
      });

      if (response['success']) {
        Get.back();
        Get.snackbar('Succès', 'Profil mis à jour !');
      } else {
        Get.snackbar(
          'Erreur',
          ApiService.extractErrorMessage(response['error'], fallback: 'Échec de la mise à jour.'),
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Enregistrer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Avatar
                  Center(
                    child: GestureDetector(
                      onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _pickedPhoto != null
                                ? FileImage(_pickedPhoto!)
                                : (_currentPhotoUrl != null
                                    ? CachedNetworkImageProvider(_currentPhotoUrl!) as ImageProvider
                                    : null),
                            child: (_pickedPhoto == null && _currentPhotoUrl == null)
                                ? Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(fontSize: 32),
                                  )
                                : null,
                          ),
                          if (_isUploadingPhoto)
                            Positioned.fill(
                              child: CircleAvatar(
                                backgroundColor: Colors.black45,
                                child: const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppConstants.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bio
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      prefixIcon: const Icon(Icons.description_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Téléphone',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email (read-only)
                  TextField(
                    controller: _emailController,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
