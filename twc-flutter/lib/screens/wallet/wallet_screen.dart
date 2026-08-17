import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiService _api = Get.find<ApiService>();

  double _balance = 0;
  double _savings = 0;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final balance = await _api.get('/transactions/balance');
      final history = await _api.get('/transactions/history');

      if (balance['success']) {
        setState(() {
          // Le backend renvoie 'boost_balance' / 'savings_balance'
          _balance = double.tryParse('${balance['data']['boost_balance'] ?? 0}') ?? 0;
          _savings = double.tryParse('${balance['data']['savings_balance'] ?? 0}') ?? 0;
        });
      }

      if (history['success']) {
        setState(() {
          _transactions = List<Map<String, dynamic>>.from(
            history['data']['transactions'] ?? [],
          );
          if (_transactions.length > 10) {
            _transactions = _transactions.sublist(0, 10);
          }
        });
      }
    } catch (e) {
      print('Error loading wallet data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💰 Portefeuille',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Balance
                  Container(
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
                        const Text(
                          'Solde disponible',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${NumberFormat('#,##0', 'fr_FR').format(_balance)} CDF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _showDepositDialog(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppConstants.primaryColor,
                                ),
                                child: const Text('📥 Déposer'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showWithdrawDialog(),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white),
                                ),
                                child: const Text('📤 Retirer'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Savings
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.savings,
                                color: Colors.blue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Épargne',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${NumberFormat('#,##0', 'fr_FR').format(_savings)} CDF',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => Get.toNamed('/savings'),
                          child: const Text('Voir'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // History
                  const Text(
                    '📋 Historique des transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_transactions.isEmpty)
                    Center(
                      child: Text(
                        'Aucune transaction',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  else
                    ..._transactions.map((transaction) => _buildTransactionItem(transaction)),
                  if (_transactions.length >= 10)
                    TextButton(
                      onPressed: () => Get.toNamed('/transactions'),
                      child: const Text('Voir toutes les transactions'),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/transfer'),
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.send, color: Colors.white),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isCredit = transaction['type'] == 'deposit' ||
        transaction['type'] == 'transfer_received';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isCredit
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        child: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          color: isCredit ? Colors.green : Colors.red,
        ),
      ),
      title: Text(
        transaction['type_label'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        transaction['description'] ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            transaction['formatted_amount'] ?? '',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
          Text(
            transaction['created_at'] != null
                ? (() {
                    try {
                      return DateFormat('dd/MM HH:mm').format(
                        DateTime.tryParse(transaction['created_at']) ?? DateTime.now(),
                      );
                    } catch (_) {
                      return '';
                    }
                  })()
                : '',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _showDepositDialog() {
    final amountController = TextEditingController();
    final emailController = TextEditingController();
    String selectedProvider = 'orange';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Déposer des fonds'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant (CDF)',
                    hintText: 'Minimum: 500',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Votre email pour le paiement',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedProvider,
                  decoration: const InputDecoration(labelText: 'Opérateur'),
                  items: const [
                    DropdownMenuItem(value: 'orange', child: Text('Orange Money')),
                    DropdownMenuItem(value: 'mtn', child: Text('MTN Mobile Money')),
                    DropdownMenuItem(value: 'vodacom', child: Text('Vodacom M-Pesa')),
                    DropdownMenuItem(value: 'airtel', child: Text('Airtel Money')),
                    DropdownMenuItem(value: 'africell', child: Text('Africell Money')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedProvider = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                final email = emailController.text.trim();

                if (amount == null || amount < 500) {
                  Get.snackbar('Erreur', 'Montant minimum: 500 CDF');
                  return;
                }
                if (email.isEmpty || !email.contains('@')) {
                  Get.snackbar('Erreur', 'Email valide requis.');
                  return;
                }

                Get.back();

                try {
                  final response = await _api.post('/transactions/deposit', data: {
                    'amount': amount,
                    'email': email,
                    'provider': selectedProvider,
                  });

                  if (response['success']) {
                    final paymentUrl = response['data']['payment_url'];
                    final txId = response['data']['transaction']?['id'];
                    if (paymentUrl != null) {
                      Get.snackbar('Paiement', 'Redirection vers Chariow...');
                      launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
                      if (txId != null) {
                        Future.delayed(const Duration(seconds: 10), () async {
                          try {
                            await _api.get('/transactions/$txId/check-status');
                            _loadData();
                          } catch (_) {}
                        });
                        Future.delayed(const Duration(seconds: 30), () async {
                          try {
                            await _api.get('/transactions/$txId/check-status');
                            _loadData();
                          } catch (_) {}
                        });
                      }
                    } else {
                      Get.snackbar('Succès', 'Demande de dépôt envoyée.');
                    }
                    _loadData();
                  } else {
                    Get.snackbar(
                      'Erreur',
                      ApiService.extractErrorMessage(response['error'], fallback: 'Échec du dépôt.'),
                    );
                  }
                } catch (e) {
                  Get.snackbar('Erreur', 'Erreur réseau.');
                }
              },
              child: const Text('Déposer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog() {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedProvider = 'orange';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Retirer des fonds'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant (CDF)',
                    hintText: 'Minimum: 1000',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone',
                    hintText: 'Ex: 650000000',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedProvider,
                  decoration: const InputDecoration(labelText: 'Opérateur'),
                  items: const [
                    DropdownMenuItem(value: 'orange', child: Text('Orange Money')),
                    DropdownMenuItem(value: 'mtn', child: Text('MTN Mobile Money')),
                    DropdownMenuItem(value: 'vodacom', child: Text('Vodacom M-Pesa')),
                    DropdownMenuItem(value: 'airtel', child: Text('Airtel Money')),
                    DropdownMenuItem(value: 'africell', child: Text('Africell Money')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedProvider = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                final phone = phoneController.text.trim();

                if (amount == null || amount < 1000) {
                  Get.snackbar('Erreur', 'Montant minimum: 1000 CDF');
                  return;
                }
                if (phone.isEmpty) {
                  Get.snackbar('Erreur', 'Numéro de téléphone requis.');
                  return;
                }

                Get.back();

                try {
                  final response = await _api.post('/transactions/withdraw', data: {
                    'amount': amount,
                    'phone': phone,
                    'provider': selectedProvider,
                  });

                  if (response['success']) {
                    Get.snackbar('Succès', 'Demande de retrait envoyée.');
                    _loadData();
                  } else {
                    Get.snackbar(
                      'Erreur',
                      ApiService.extractErrorMessage(response['error'], fallback: 'Échec du retrait.'),
                    );
                  }
                } catch (e) {
                  Get.snackbar('Erreur', 'Erreur réseau.');
                }
              },
              child: const Text('Retirer'),
            ),
          ],
        ),
      ),
    );
  }
}
