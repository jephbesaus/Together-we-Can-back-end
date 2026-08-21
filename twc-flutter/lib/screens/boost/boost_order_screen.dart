import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/formatters.dart';
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

  // Limites demandées : quantité entre 100 et 300000. Les bornes du service
  // s'appliquent si plus strictes.
  int get _min {
    final serviceMin = int.tryParse('${widget.service['min']}') ?? 100;
    return serviceMin < 100 ? 100 : serviceMin;
  }

  int get _max {
    final serviceMax = int.tryParse('${widget.service['max']}') ?? 300000;
    return serviceMax > 300000 ? 300000 : serviceMax;
  }

  // Tarif en CDF / 1000 : utilise la valeur convertie par le backend
  // (price_per_1000) ; sinon convertit localement le tarif USD (× 3300).
  double get _pricePer1000 {
    final converted = double.tryParse('${widget.service['price_per_1000'] ?? ''}');
    if (converted != null && converted > 0) return converted;
    final usdRate = double.tryParse('${widget.service['rate'] ?? 0}') ?? 0;
    return usdRate * 3300;
  }

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
                    'Prix: ${Formatters.cdf(_pricePer1000)} / 1000',
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
                hintText: 'Entre $_min et $_max',
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
                    '${_estimatedPrice.toStringAsFixed(0)} CDF',
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
