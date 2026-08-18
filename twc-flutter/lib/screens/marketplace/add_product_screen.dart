import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ApiService _api = Get.find<ApiService>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

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

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.replaceAll(' ', ''));

    if (name.isEmpty) {
      Get.snackbar('Erreur', 'Le nom du produit est requis.');
      return;
    }
    if (price == null || price <= 0) {
      Get.snackbar('Erreur', 'Entrez un prix valide (CDF).');
      return;
    }
    if (_selectedImages.isEmpty) {
      Get.snackbar('Erreur', 'Ajoutez au moins une photo.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final formData = FormData();
      formData.fields.add(MapEntry('name', name));
      formData.fields.add(MapEntry('price', price.toStringAsFixed(0)));
      formData.fields.add(MapEntry('category', _categoryController.text.trim()));
      formData.fields.add(MapEntry('description', _descriptionController.text.trim()));
      formData.fields.add(MapEntry('location', _locationController.text.trim()));
      formData.fields.add(MapEntry('contact_info', _contactController.text.trim()));
      if (_stockController.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry('stock_quantity', _stockController.text.trim()));
      }

      for (final image in _selectedImages) {
        formData.files.add(MapEntry(
          'images[]',
          await MultipartFile.fromFile(image.path, filename: image.name),
        ));
      }

      final response = await _api.multipart('/marketplace/products', formData);

      if (response['success']) {
        Get.back(result: true);
        Get.snackbar(
          'Produit soumis',
          'Votre produit sera visible après validation par l\'équipe.',
        );
      } else {
        Get.snackbar(
          'Erreur',
          ApiService.extractErrorMessage(response['error'], fallback: 'Échec de l\'ajout du produit.'),
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ajouter un produit'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photos
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  InkWell(
                    onTap: _pickImages,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 28, color: AppConstants.primaryColor),
                          SizedBox(height: 4),
                          Text(
                            'Photos',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ..._selectedImages.map((image) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(image.path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedImages.remove(image)),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _field(_nameController, 'Nom du produit', Icons.sell_outlined),
            const SizedBox(height: 12),
            _field(_priceController, 'Prix (CDF)', Icons.payments_outlined,
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _field(_categoryController, 'Catégorie', Icons.category_outlined),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _decoration('Description', Icons.notes),
            ),
            const SizedBox(height: 12),
            _field(_locationController, 'Localisation', Icons.location_on_outlined),
            const SizedBox(height: 12),
            _field(_contactController, 'Contact', Icons.phone_outlined),
            const SizedBox(height: 12),
            _field(_stockController, 'Stock (optionnel)', Icons.inventory_2_outlined,
                keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'Envoi...' : 'Publier le produit',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _decoration(label, icon),
    );
  }
}
