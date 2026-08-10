import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final ApiService _api = Get.find<ApiService>();
  bool _isPremium = false;
  bool _premiumRequested = false;
  bool _isLoading = true;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/user/premium/status');
      if (response['success']) {
        setState(() {
          _isPremium = response['data']['is_premium'] ?? false;
          _premiumRequested = response['data']['premium_requested'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading premium status: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _requestPremium() async {
    setState(() => _isRequesting = true);
    try {
      final response = await _api.post('/user/premium/request');
      if (response['success']) {
        Get.snackbar('Demande envoyée', 'Votre demande Premium est en attente de validation.');
        _loadStatus();
      } else {
        Get.snackbar(
          'Erreur',
          ApiService.extractErrorMessage(response['error'], fallback: 'Échec de la demande.'),
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
    setState(() => _isRequesting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('👑 Together Mode Premium'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00A86B), Color(0xFF008C5A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.verified, color: Colors.white, size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          'Badge vérifié Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Prix : 10 000 FC',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Avantages',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _advantage('✅', 'Badge bleu "Vérifié"'),
                  _advantage('💰', 'Réduction de 20% sur Clic-Boost'),
                  _advantage('🎁', 'Contenus exclusifs'),
                  _advantage('🎧', 'Support prioritaire'),
                  const SizedBox(height: 24),
                  if (_isPremium)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Vous êtes déjà membre Premium !'),
                        ],
                      ),
                    )
                  else if (_premiumRequested)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.hourglass_top, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(child: Text('Demande en attente de validation par l\'admin.')),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isRequesting ? null : _requestPremium,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                        ),
                        child: _isRequesting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Demander le badge Premium',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _advantage(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }
}
