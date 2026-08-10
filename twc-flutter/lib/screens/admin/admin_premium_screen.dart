import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class AdminPremiumScreen extends StatefulWidget {
  const AdminPremiumScreen({super.key});

  @override
  State<AdminPremiumScreen> createState() => _AdminPremiumScreenState();
}

class _AdminPremiumScreenState extends State<AdminPremiumScreen> {
  final ApiService _api = Get.find<ApiService>();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/admin/premium-requests');
      if (response['success']) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(response['data']['requests'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading premium requests: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _decide(int id, bool approve) async {
    try {
      final response = await _api.post('/admin/premium-requests/$id/${approve ? 'approve' : 'reject'}');
      if (response['success']) {
        Get.snackbar('Succès', approve ? 'Demande approuvée.' : 'Demande refusée.');
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
        title: const Text('Demandes Premium'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('Aucune demande en attente'))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final user = _requests[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.verified, color: AppConstants.primaryColor),
                        title: Text(user['name'] ?? ''),
                        subtitle: Text(user['email'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => _decide(user['id'], true),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _decide(user['id'], false),
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
