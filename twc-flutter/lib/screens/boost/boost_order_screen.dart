import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../boost_home_screen.dart';

class BoostOrderScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final String platform;
  final String platformName;

  const BoostOrderScreen({
    super.key,
    required this.service,
    required this.platform,
    required this.platformName,
  });

  @override
  State<BoostOrderScreen> createState() => _BoostOrderScreenState();
}

class _BoostOrderScreenState extends State<BoostOrderScreen> {
  final ApiService _api = Get.find<ApiService>();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  bool _isSubmitting = false;

  int get _min => int.tryParse('${widget.service['min'] ?? 100}') ?? 100;
  int get _max => int.tryParse('${widget.service['max'] ?? 10000}') ?? 10000;
  double get _pricePer1000 => double.tryParse('${widget.service['price_per_1000'] ?? widget.service['rate'] ?? 0}') ?? 0;

  double get _estimatedPrice {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    return (_pricePer1000 * qty) / 1000;
  }

  @override
  void initState() {
    super.initState();
    _quantityController.text = _min.toString();
    _quantityController.addListener(() => setState(() {}));
  }

  Future<void> _submitOrder() async {
    final link = _linkController.text.trim();
    final quantity = int.tryParse(_quantityController.text);

    if (link.isEmpty) {
      Get.snackbar('Erreur', 'Le lien de la publication est requis.');
      return;
    }
    if (quantity == null || quantity < _min || quantity > _max) {
      Get.snackbar('Erreur', 'Quantité invalide (entre $_min et $_max).');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await _api.post('/boost/order', data: {
        'platform': widget.platform,
        'service_id': widget.service['id'] ?? widget.service['service'],
        'link': link,
        'quantity': quantity,
      });

      if (response['success']) {
        Get.offAll(() => const BoostHomeScreen());
        Get.snackbar('Commande lancée 🚀', 'Votre commande a été envoyée avec succès.');
      } else {
        Get.snackbar(
          'Erreur',
          ApiService.extractErrorMessage(response['error'], fallback: 'Échec de la commande.'),
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Commander - ${widget.platformName}'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.service['name'] ?? 'Service',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text('Min: $_min • Max: $_max', style: TextStyle(color: Colors.grey[600])),
                  Text(
                    'Prix: ${_pricePer1000.toStringAsFixed(0)} FCFA / 1000',
                    style: const TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Lien de la publication', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _linkController,
              decoration: InputDecoration(
                hintText: 'https://...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Quantité (entre $_min et $_max)', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Prix estimé', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${_estimatedPrice.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '🔥 Lancer la commande',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
