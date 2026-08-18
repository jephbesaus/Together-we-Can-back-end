import 'package:flutter/material.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import 'package:get/get.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final ApiService _api = Get.find<ApiService>();
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAbout();
  }

  Future<void> _loadAbout() async {
    try {
      final response = await _api.get('/about');
      if (response['success']) {
        setState(() => _data = response['data']);
      }
    } catch (e) {
      print('Error loading about: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('À propos'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('Impossible de charger les informations.'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: AppConstants.primaryColor,
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 56,
                              height: 56,
                              errorBuilder: (_, __, ___) => const Text(
                                'TWC',
                                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _data!['app_name'] ?? 'Together We Can',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _data!['tagline'] ?? '',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500], fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _section('Notre mission', _data!['mission'] ?? ''),
                    _section('Notre vision', _data!['vision'] ?? ''),
                    const SizedBox(height: 16),
                    const Text(
                      'Ce que nous offrons',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...(_data!['what_we_offer'] as List? ?? []).map((item) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: Icon(Icons.check_circle, color: AppConstants.primaryColor),
                            title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Text(item['description'] ?? '', style: TextStyle(color: Colors.grey[600])),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                    const Text(
                      'Nos valeurs',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...((_data!['values'] as Map<String, dynamic>? ?? {}).entries.map((e) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(Icons.star, color: AppConstants.primaryColor, size: 20),
                            title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(e.value, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ),
                        ))),
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        'Together We Can  •  Version ${AppConstants.appVersion}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(color: Colors.grey[600], height: 1.5)),
        ],
      ),
    );
  }
}
