import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class AdminMarketplaceScreen extends StatefulWidget {
  const AdminMarketplaceScreen({super.key});

  @override
  State<AdminMarketplaceScreen> createState() => _AdminMarketplaceScreenState();
}

class _AdminMarketplaceScreenState extends State<AdminMarketplaceScreen> {
  final ApiService _api = Get.find<ApiService>();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/admin/marketplace/products', params: {'status': _filter});
      if (response['success']) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(response['data']['products'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading products: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _decide(int id, bool approve) async {
    try {
      final response = await _api.post('/admin/marketplace/products/$id/${approve ? 'approve' : 'reject'}');
      if (response['success']) {
        Get.snackbar('Succès', approve ? 'Produit approuvé.' : 'Produit refusé.');
        _load();
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Marketplace - Modération'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('En attente'),
                  selected: _filter == 'pending',
                  onSelected: (_) {
                    setState(() => _filter = 'pending');
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Approuvés'),
                  selected: _filter == 'approved',
                  onSelected: (_) {
                    setState(() => _filter = 'approved');
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('Aucun produit'))
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final images = product['images'] as List?;
                          final mainImage = images != null && images.isNotEmpty ? images[0] : null;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: mainImage != null
                                  ? CircleAvatar(backgroundImage: CachedNetworkImageProvider(mainImage))
                                  : const CircleAvatar(child: Icon(Icons.image)),
                              title: Text(product['name'] ?? ''),
                              subtitle: Text(product['formatted_price'] ?? ''),
                              trailing: _filter == 'pending'
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.check_circle, color: Colors.green),
                                          onPressed: () => _decide(product['id'], true),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.cancel, color: Colors.red),
                                          onPressed: () => _decide(product['id'], false),
                                        ),
                                      ],
                                    )
                                  : const Icon(Icons.check, color: Colors.green),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
