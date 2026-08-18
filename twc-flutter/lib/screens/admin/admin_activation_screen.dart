import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../auth/login_screen.dart';
import 'admin_dashboard_screen.dart';

class AdminActivationScreen extends StatefulWidget {
  const AdminActivationScreen({super.key});

  @override
  State<AdminActivationScreen> createState() => _AdminActivationScreenState();
}

class _AdminActivationScreenState extends State<AdminActivationScreen> {
  final ApiService _api = Get.find<ApiService>();
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _checkAndActivate();
  }

  Future<void> _checkAndActivate() async {
    // First try to access dashboard (already activated?)
    try {
      final dashboard = await _api.get('/admin/dashboard');
      if (dashboard['success'] == true) {
        Get.offAll(() => const AdminDashboardScreen());
        return;
      }
    } catch (_) {}

    // Not activated yet — activate automatically
    try {
      final response = await _api.post('/admin/activate', data: {});
      if (response['success'] == true) {
        Get.offAll(() => const AdminDashboardScreen());
        Get.snackbar('Bienvenue', 'Accès administrateur activé.');
        return;
      }

      final msg = ApiService.extractErrorMessage(
        response['error'],
        fallback: 'Accès refusé.',
      );

      setState(() {
        _isLoading = false;
        _errorMsg = msg;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _errorMsg = 'Erreur réseau. Vérifiez votre connexion.';
      });
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
                  Text('Vérification en cours...'),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Accès administrateur refusé',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMsg ?? 'Seul le compte administrateur autorisé peut accéder.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () => Get.back(),
                        child: const Text('Retour'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() => _isLoading = true);
                          await Get.find<ApiService>().logout();
                          Get.offAll(() => const LoginScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                        ),
                        child: const Text('Se reconnecter', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
