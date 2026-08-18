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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAndActivate();
  }

  Future<void> _checkAndActivate() async {
    // First try to access dashboard (already activated?)
    try {
      final dashboard = await _api.get('/admin/dashboard');
      if (dashboard['success']) {
        Get.offAll(() => const AdminDashboardScreen());
        return;
      }
    } catch (_) {}

    // Not activated yet — activate automatically
    try {
      final response = await _api.post('/admin/activate', data: {});
      if (response['success']) {
        Get.offAll(() => const AdminDashboardScreen());
        Get.snackbar('Bienvenue', 'Accès administrateur activé.');
        return;
      } else {
        // Wrong email or not authorized
        final msg = ApiService.extractErrorMessage(response['error'], fallback: 'Accès refusé.');
        setState(() => _isLoading = false);
        Get.snackbar('Erreur', msg);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.admin_panel_settings, size: 64, color: AppConstants.primaryColor),
                  SizedBox(height: 24),
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Activation en cours...'),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Accès administrateur refusé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Seul le compte administrateur autorisé peut accéder.'),
                ],
              ),
      ),
    );
  }
}
