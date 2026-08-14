import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../widgets/app_loader.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final ApiService _api = Get.find<ApiService>();

  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await _api.get('/transactions/history', params: {'limit': 100});
      if (response['success']) {
        setState(() {
          _transactions = List<Map<String, dynamic>>.from(
            response['data']['transactions'] ?? [],
          );
        });
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() => _hasError = true);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Toutes les transactions'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const AppLoadingView(message: 'Chargement des transactions...')
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Impossible de charger les transactions.'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadTransactions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _transactions.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune transaction',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTransactions,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          return _buildTransactionItem(_transactions[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isCredit = transaction['type'] == 'deposit' ||
        transaction['type'] == 'transfer_received';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCredit
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
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
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
            if (transaction['created_at'] != null)
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(
                  DateTime.parse(transaction['created_at']).toLocal(),
                ),
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}
