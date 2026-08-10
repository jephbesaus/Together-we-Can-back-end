import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import 'admin_dashboard_screen.dart';

class AdminActivationScreen extends StatefulWidget {
  const AdminActivationScreen({super.key});

  @override
  State<AdminActivationScreen> createState() => _AdminActivationScreenState();
}

class _AdminActivationScreenState extends State<AdminActivationScreen> {
  final ApiService _api = Get.find<ApiService>();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _activate() async {
    if (_codeController.text.trim().isEmpty) {
      Get.snackbar('Erreur', 'Entrez le code d\'activation.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _api.post('/admin/activate', data: {
        'code': _codeController.text.trim(),
      });

      if (response['success']) {
        Get.offAll(() => const AdminDashboardScreen());
        Get.snackbar('Bienvenue', 'Accès administrateur activé.');
      } else {
        Get.snackbar(
          'Erreur',
          ApiService.extractErrorMessage(response['error'], fallback: 'Code incorrect.'),
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accès administrateur')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.admin_panel_settings, size: 64, color: AppConstants.primaryColor),
            const SizedBox(height: 16),
            const Text('Code d\'activation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Entrez le code fourni pour accéder au tableau de bord admin.',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Code',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _activate,
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Activer', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
