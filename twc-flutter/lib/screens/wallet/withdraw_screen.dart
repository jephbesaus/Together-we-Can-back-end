import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final ApiService _api = Get.find<ApiService>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedProvider = 'airtel';
  double _balance = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _providers = [
    {'value': 'airtel', 'label': 'Airtel Money', 'icon': Icons.phone_android, 'color': Colors.red},
    {'value': 'orange', 'label': 'Orange Money', 'icon': Icons.phone_android, 'color': Colors.orange},
    {'value': 'mpesa', 'label': 'M-Pesa (Vodacom)', 'icon': Icons.phone_android, 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/transactions/balance');
      if (response['success']) {
        setState(() {
          _balance = double.tryParse('${response['data']['boost_balance'] ?? 0}') ?? 0;
        });
      }
    } catch (e) {
      print('Error loading balance: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _submitWithdraw() async {
    final amount = double.tryParse(_amountController.text);
    final phone = _phoneController.text.trim();

    if (amount == null || amount <= 0) {
      Get.snackbar('Erreur', 'Montant invalide.');
      return;
    }
    if (amount < 1000) {
      Get.snackbar('Erreur', 'Montant minimum: 1 000 CDF');
      return;
    }
    if (amount > _balance) {
      Get.snackbar('Erreur', 'Solde insuffisant.');
      return;
    }
    if (phone.isEmpty || phone.length < 9) {
      Get.snackbar('Erreur', 'Numéro de téléphone invalide.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await _api.post('/transactions/withdraw', data: {
        'amount': amount,
        'phone': phone,
        'provider': _selectedProvider,
      });

      if (response['success']) {
        final txId = response['data']?['transaction']?['id'] ?? '';
        _showSuccessDialog(txId.toString(), amount);
        _amountController.clear();
        _phoneController.clear();
        _loadBalance();
      } else {
        Get.snackbar(
          'Erreur',
          ApiService.extractErrorMessage(response['error'], fallback: 'Échec du retrait.'),
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }

    setState(() => _isSubmitting = false);
  }

  void _showSuccessDialog(String txId, double amount) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Retrait envoyé'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Montant : ${NumberFormat('#,##0', 'fr_FR').format(amount)} CDF'),
            const SizedBox(height: 4),
            Text('Téléphone : $_phoneController.text'),
            const SizedBox(height: 4),
            Text('Opérateur : ${_providers.firstWhere((p) => p['value'] == _selectedProvider)['label']}'),
            if (txId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('ID Transaction : $txId', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Retrait'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance card
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
                        const Text(
                          'Solde disponible',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${NumberFormat('#,##0', 'fr_FR').format(_balance)} CDF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Phone number
                  const Text(
                    'Numéro de téléphone',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Ex: 650000000',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Provider selector
                  const Text(
                    'Opérateur',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ..._providers.map((provider) {
                    final isSelected = _selectedProvider == provider['value'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedProvider = provider['value']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppConstants.primaryColor.withOpacity(0.1)
                              : isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppConstants.primaryColor : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(provider['icon'] as IconData, color: provider['color'] as Color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                provider['label'],
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: AppConstants.primaryColor),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Amount
                  const Text(
                    'Montant (CDF)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Minimum: 1 000',
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  // Quick amount buttons
                  Row(
                    children: [1000, 5000, 10000, 25000].map((amt) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: OutlinedButton(
                            onPressed: () => _amountController.text = amt.toString(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              '${NumberFormat('#,##0', 'fr_FR').format(amt)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitWithdraw,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Retirer',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
