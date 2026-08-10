import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class AdminBoostScreen extends StatefulWidget {
  const AdminBoostScreen({super.key});

  @override
  State<AdminBoostScreen> createState() => _AdminBoostScreenState();
}

class _AdminBoostScreenState extends State<AdminBoostScreen> {
  final ApiService _api = Get.find<ApiService>();
  List<Map<String, dynamic>> _orders = [];
  dynamic _balance;
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _api.get('/admin/boost/orders');
      if (orders['success']) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(orders['data']['orders'] ?? []);
        });
      }
      final balance = await _api.get('/admin/boost/fullsmm-balance');
      if (balance['success']) {
        setState(() => _balance = balance['data']['balance']);
      }
    } catch (e) {
      print('Error loading boost admin data: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _syncServices() async {
    setState(() => _isSyncing = true);
    try {
      final response = await _api.post('/admin/boost/services/sync');
      if (response['success']) {
        Get.snackbar('Succès', '${response['data']['count'] ?? 0} services synchronisés.');
      } else {
        Get.snackbar('Erreur', 'Échec de la synchronisation (vérifiez la clé FullSMM).');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
    setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Clic-Boost - Administration'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Solde FullSMM', style: TextStyle(fontSize: 12)),
                              Text(
                                _balance != null ? '${_balance['balance'] ?? _balance}' : '—',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _isSyncing ? null : _syncServices,
                            icon: _isSyncing
                                ? const SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.sync, size: 18),
                            label: const Text('Sync services'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Commandes récentes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ..._orders.map((order) => ListTile(
                        title: Text(order['service_name'] ?? 'Service'),
                        subtitle: Text('${order['platform']} • ${order['status']}'),
                        trailing: Text(order['formatted_price'] ?? ''),
                      )),
                ],
              ),
            ),
    );
  }
}
