import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final ApiService _api = Get.find<ApiService>();
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/admin/reports', params: {'status': 'pending'});
      if (response['success']) {
        setState(() {
          _reports = List<Map<String, dynamic>>.from(response['data']['reports'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading reports: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _resolve(int id, String action) async {
    try {
      final response = await _api.post('/admin/reports/$id/resolve', data: {
        'action': action,
      });
      if (response['success']) {
        Get.snackbar('Succès', 'Signalement traité.');
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
        title: const Text('Signalements'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? const Center(child: Text('Aucun signalement en attente'))
              : ListView.builder(
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    final reporter = report['reporter'] ?? {};
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Signalé par ${reporter['name'] ?? 'Anonyme'}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(report['reason'] ?? ''),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _resolve(report['id'], 'none'),
                                  child: const Text('Ignorer'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _resolve(report['id'], 'hide_post'),
                                  child: const Text('Masquer le post'),
                                ),
                                ElevatedButton(
                                  onPressed: () => _resolve(report['id'], 'delete_post'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Supprimer le post', style: TextStyle(color: Colors.white)),
                                ),
                                ElevatedButton(
                                  onPressed: () => _resolve(report['id'], 'block_user'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                  child: const Text('Bloquer l\'auteur', style: TextStyle(color: Colors.white)),
                                ),
                              ],
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
