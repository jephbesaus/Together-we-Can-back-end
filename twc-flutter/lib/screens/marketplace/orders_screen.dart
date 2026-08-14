import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/api_service.dart';
import '../../core/services/media_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ApiService _api = Get.find<ApiService>();

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/marketplace/orders');
      if (response['success']) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(
            response['data']['orders'] ?? [],
          );
        });
      }
    } catch (e) {
      print('Error loading orders: $e');
    }
    setState(() => _isLoading = false);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return '⏳ En attente';
      case 'confirmed':
        return '✅ Confirmée';
      case 'processing':
        return '🔄 En préparation';
      case 'shipped':
        return '🚚 Expédiée';
      case 'delivered':
        return '📦 Livrée';
      case 'completed':
        return '🎉 Terminée';
      case 'cancelled':
        return '❌ Annulée';
      case 'refunded':
        return '💳 Remboursée';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'completed':
        return Colors.green;
      case 'processing':
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.teal;
      case 'cancelled':
      case 'refunded':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mes commandes'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune commande',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vos commandes apparaîtront ici.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final product = order['product'] as Map<String, dynamic>? ?? {};
                    final productName = product['name'] ?? 'Produit';
                    final productImage = product['main_image'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: productImage != null
                                  ? CachedNetworkImage(
                                      imageUrl: MediaService.resolveUrl(productImage)!,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => Container(
                                        width: 64,
                                        height: 64,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image_not_supported),
                                      ),
                                    )
                                  : Container(
                                      width: 64,
                                      height: 64,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.shopping_bag),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order['quantity']} x ${order['formatted_total_price'] ?? '${order['total_price']} FCFA'}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(order['status'] ?? '')
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _statusLabel(order['status'] ?? ''),
                                      style: TextStyle(
                                        color: _statusColor(order['status'] ?? ''),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (order['created_at'] != null)
                              Text(
                                DateTime.parse(order['created_at'])
                                    .toLocal()
                                    .toString()
                                    .substring(0, 10),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
