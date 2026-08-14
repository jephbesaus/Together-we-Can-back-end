import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/constants.dart';
import '../core/services/api_service.dart';
import '../widgets/app_loader.dart';
import 'boost/select_service_screen.dart';

class BoostHomeScreen extends StatefulWidget {
  const BoostHomeScreen({super.key});

  @override
  State<BoostHomeScreen> createState() => _BoostHomeScreenState();
}

class _BoostHomeScreenState extends State<BoostHomeScreen> {
  final ApiService _api = Get.find<ApiService>();

  List<Map<String, dynamic>> _platforms = [];
  double _balance = 0;
  List<Map<String, dynamic>> _recentOrders = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final platforms = await _api.get('/boost/platforms');
      final balance = await _api.get('/boost/balance');
      final orders = await _api.get('/boost/orders');

      if (platforms['success']) {
        setState(() {
          _platforms = List<Map<String, dynamic>>.from(
            platforms['data']['platforms'] ?? [],
          );
        });
      }

      if (balance['success']) {
        setState(() {
          // Le backend renvoie 'boost_balance', pas 'wallet_balance'
          _balance = (balance['data']['boost_balance'] ?? 0).toDouble();
        });
      }

      if (orders['success']) {
        setState(() {
          _recentOrders = List<Map<String, dynamic>>.from(
            orders['data']['orders'] ?? [],
          );
          if (_recentOrders.length > 5) {
            _recentOrders = _recentOrders.sublist(0, 5);
          }
        });
      }
    } catch (e) {
      print('Error loading boost data: $e');
      setState(() => _hasError = true);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const AppLoadingView(message: 'Chargement du Clic-Boost...')
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Impossible de charger les données Boost.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  title: const Text('🚀 Clic-Boost'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.history),
                      onPressed: () => Get.toNamed('/boost-history'),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
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
                          '💳 Solde Boost',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_balance.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _showDepositDialog(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppConstants.primaryColor,
                                ),
                                child: const Text('➕ Recharger'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Get.toNamed('/boost-history'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white),
                                ),
                                child: const Text('📊 Historique'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📱 Choisissez votre réseau',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: _platforms.isEmpty
                      ? SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.cloud_off,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Aucune plateforme disponible pour le moment.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: _loadData,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final platform = _platforms[index];
                        return _buildPlatformCard(platform);
                      },
                      childCount: _platforms.length,
                    ),
                  ),
                ),
                if (_recentOrders.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '📋 Dernières commandes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Get.toNamed('/boost-orders'),
                            child: const Text('Voir tout'),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _recentOrders.length) return null;
                      final order = _recentOrders[index];
                      return _buildOrderItem(order);
                    },
                    childCount: _recentOrders.length,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildPlatformCard(Map<String, dynamic> platform) {
    final color = platform['color'] ?? '#00A86B';

    return InkWell(
      onTap: () {
        Get.to(() => SelectServiceScreen(
              platformId: platform['id'],
              platformName: platform['name'],
            ));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getPlatformIcon(platform['icon']),
              size: 36,
              color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
            ),
            const SizedBox(height: 8),
            Text(
              platform['name'] ?? '',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPlatformIcon(String? icon) {
    switch (icon) {
      case 'youtube':
        return Icons.play_circle_filled;
      case 'tiktok':
        return Icons.music_note;
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'twitter':
        return Icons.chat;
      case 'telegram':
        return Icons.telegram;
      case 'whatsapp':
        return Icons.chat_bubble;
      default:
        return Icons.share;
    }
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    Color statusColor;
    String statusText;

    switch (order['status']) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = '⏳ En attente';
        break;
      case 'processing':
        statusColor = Colors.blue;
        statusText = '🔄 En cours';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = '✅ Terminée';
        break;
      case 'failed':
        statusColor = Colors.red;
        statusText = '❌ Échouée';
        break;
      default:
        statusColor = Colors.grey;
        statusText = order['status'] ?? '';
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.1),
        child: Icon(
          Icons.trending_up,
          color: statusColor,
        ),
      ),
      title: Text(
        order['service_name'] ?? 'Service',
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${order['quantity']} • ${order['formatted_price']}',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            order['created_at'] != null
                ? DateTime.parse(order['created_at'])
                    .toLocal()
                    .toString()
                    .substring(0, 16)
                : '',
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showDepositDialog() {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedProvider = 'orange';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Recharger le portefeuille Boost'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant (FCFA)',
                    hintText: 'Minimum: 500',
                    prefixText: 'FCFA ',
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

                if (amount == null || amount < 500) {
                  Get.snackbar('Erreur', 'Montant minimum: 500 FCFA');
                  return;
                }
                if (phone.isEmpty) {
                  Get.snackbar('Erreur', 'Numéro de téléphone requis.');
                  return;
                }

                Get.back();

                try {
                  final response = await _api.post('/boost/deposit', data: {
                    'amount': amount,
                    'phone': phone,
                    'provider': selectedProvider,
                  });

                  if (response['success']) {
                    Get.snackbar('Succès', 'Demande de dépôt envoyée.');
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
              child: const Text('Recharger'),
            ),
          ],
        ),
      ),
    );
  }
}
