import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import 'boost_order_screen.dart';

class SelectServiceScreen extends StatefulWidget {
  final String platformId;
  final String platformName;

  const SelectServiceScreen({
    super.key,
    required this.platformId,
    required this.platformName,
  });

  @override
  State<SelectServiceScreen> createState() => _SelectServiceScreenState();
}

class _SelectServiceScreenState extends State<SelectServiceScreen> {
  final ApiService _api = Get.find<ApiService>();

  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);

    try {
      final response = await _api.get('/boost/services/${widget.platformId}');

      if (response['success']) {
        setState(() {
          _services = List<Map<String, dynamic>>.from(
            response['data']['services'] ?? [],
          );
        });
      }
    } catch (e) {
      print('Error loading services: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Services - ${widget.platformName}'),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun service disponible',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadServices,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          service['name'] ?? 'Service',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Min: ${service['min']} - Max: ${service['max']}'),
                            Text(
                              'Prix: ${service['price_per_1000'] ?? 0} FCFA / 1000',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Get.to(() => BoostOrderScreen(
                                service: service,
                                platform: widget.platformId,
                                platformName: widget.platformName,
                              ));
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
