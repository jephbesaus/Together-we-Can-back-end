import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final ApiService _api = Get.find<ApiService>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;

  Future<void> _sendTransfer() async {
    final email = _emailController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (email.isEmpty) {
      Get.snackbar('Erreur', 'Email du destinataire requis.');
      return;
    }

    if (amount == null || amount <= 0) {
      Get.snackbar('Erreur', 'Montant invalide.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Le backend cherche via le paramètre 'q' (nom OU email), pas 'email'
      final userResponse = await _api.get('/users/search', params: {
        'q': email,
      });

      final users = userResponse['success']
          ? (userResponse['data']['users'] as List)
          : [];

      // On vérifie que l'email correspond exactement (la recherche backend est partielle)
      final match = users.firstWhere(
        (u) => (u['email'] ?? '').toString().toLowerCase() == email.toLowerCase(),
        orElse: () => null,
      );

      if (match == null) {
        Get.snackbar('Erreur', 'Utilisateur non trouvé.');
        setState(() => _isLoading = false);
        return;
      }

      final toUserId = match['id'];

      final response = await _api.post('/transactions/transfer', data: {
        'to_user_id': toUserId,
        'amount': amount,
        'description': _descriptionController.text.trim(),
      });

      if (response['success']) {
        Get.offAllNamed('/wallet');
        Get.snackbar('Succès', 'Transfert effectué avec succès !');
      } else {
        Get.snackbar(
          'Erreur',
          ApiService.extractErrorMessage(response['error'], fallback: 'Échec du transfert.'),
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('🔄 Transfert'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email du destinataire',
                hintText: 'exemple@email.com',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Montant (FCFA)',
                hintText: '1000',
                prefixIcon: Icon(Icons.money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                hintText: 'Transfert pour...',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text(
                        'Envoyer le transfert',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
