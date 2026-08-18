import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class InstructorDashboardScreen extends StatefulWidget {
  const InstructorDashboardScreen({super.key});

  @override
  State<InstructorDashboardScreen> createState() => _InstructorDashboardScreenState();
}

class _InstructorDashboardScreenState extends State<InstructorDashboardScreen> {
  final ApiService _api = Get.find<ApiService>();
  Map<String, dynamic> _stats = {};
  List<dynamic> _recentEnrollments = [];
  List<dynamic> _courseStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/instructor/dashboard');
      if (response['success']) {
        setState(() {
          _stats = response['data']['stats'] ?? {};
          _recentEnrollments = response['data']['recent_enrollments'] ?? [];
          _courseStats = response['data']['course_stats'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading instructor dashboard: $e');
    }
    setState(() => _isLoading = false);
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'approved': return 'Publiée';
      case 'submitted': return 'En attente';
      case 'rejected': return 'Refusée';
      default: return 'Brouillon';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Espace Formateur'),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDashboard),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _statCard('Formations', '${_stats['total_courses'] ?? 0}', Icons.school, Colors.blue),
                      _statCard('Publiees', '${_stats['published_courses'] ?? 0}', Icons.check_circle, Colors.green),
                      _statCard('Etudiants', '${_stats['total_students'] ?? 0}', Icons.people, Colors.purple),
                      _statCard(
                        'Revenus',
                        '${NumberFormat('#,##0', 'fr_FR').format(_stats['total_revenue'] ?? 0)} CDF',
                        Icons.account_balance_wallet,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _statCard('Note moyenne', '${_stats['average_rating'] ?? 0} *', Icons.star, Colors.amber),
                  const SizedBox(height: 24),
                  if (_courseStats.isNotEmpty) ...[
                    const Text('Mes formations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...(_courseStats as List).map((c) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppConstants.primaryColor,
                              child: Text('${c['students_count'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                            title: Text(c['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              '${c['students_count'] ?? 0} etudiants  |  ${c['rating'] ?? 0} *  |  ${_statusLabel(c['status'])}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )),
                  ],
                  if (_recentEnrollments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Dernieres inscriptions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...(_recentEnrollments as List).map((e) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                (e['user']?['name'] ?? '?')[0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(e['user']?['name'] ?? 'Utilisateur'),
                            subtitle: Text(e['course']?['title'] ?? 'Formation'),
                            trailing: Text(
                              DateFormat('dd/MM').format(DateTime.parse(e['created_at'])),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        ],
      ),
    );
  }
}
