import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import 'admin_users_screen.dart';
import 'admin_posts_screen.dart';
import 'admin_premium_screen.dart';
import 'admin_marketplace_screen.dart';
import 'admin_boost_screen.dart';
import 'admin_courses_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_announcements_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _api = Get.find<ApiService>();

  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final response = await _api.get('/admin/dashboard');
      if (response['success']) {
        setState(() {
          _stats = response['data']['stats'] ?? {};
        });
      }
    } catch (e) {
      print('Error loading admin stats: $e');
    }

    setState(() => _isLoading = false);
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('👑 Admin Dashboard'),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading || _stats.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildStatCard(index),
                      childCount: 8,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildQuickAction(Icons.people, 'Utilisateurs', () => Get.to(() => const AdminUsersScreen())),
                        _buildQuickAction(Icons.verified, 'Premium', () => Get.to(() => const AdminPremiumScreen())),
                        _buildQuickAction(Icons.article, 'Publications', () => Get.to(() => const AdminPostsScreen())),
                        _buildQuickAction(Icons.shopping_bag, 'Marketplace', () => Get.to(() => const AdminMarketplaceScreen())),
                        _buildQuickAction(Icons.trending_up, 'Boost', () => Get.to(() => const AdminBoostScreen())),
                        _buildQuickAction(Icons.book, 'Formations', () => Get.to(() => const AdminCoursesScreen())),
                        _buildQuickAction(Icons.flag, 'Signalements', () => Get.to(() => const AdminReportsScreen())),
                        _buildQuickAction(Icons.newspaper, 'Actualités', () => Get.to(() => const AdminAnnouncementsScreen())),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(int index) {
    final users = _stats['users'] ?? {};
    final content = _stats['content'] ?? {};
    final marketplace = _stats['marketplace'] ?? {};
    final boost = _stats['boost'] ?? {};
    final courses = _stats['courses'] ?? {};
    final financial = _stats['financial'] ?? {};
    final reports = _stats['reports'] ?? {};

    final cards = [
      {
        'title': 'Utilisateurs',
        'value': '${users['total'] ?? 0}',
        'subtitle': '+${users['new_today'] ?? 0} aujourd\'hui',
        'icon': Icons.people,
        'color': Colors.blue,
      },
      {
        'title': 'Publications',
        'value': '${content['posts'] ?? 0}',
        'subtitle': '${content['reported'] ?? 0} signalés',
        'icon': Icons.article,
        'color': Colors.purple,
      },
      {
        'title': 'Marketplace',
        'value': '${marketplace['products'] ?? 0}',
        'subtitle': '${marketplace['pending_approval'] ?? 0} en attente',
        'icon': Icons.shopping_bag,
        'color': Colors.orange,
      },
      {
        'title': 'Boost',
        'value': '${boost['orders'] ?? 0}',
        'subtitle': '${boost['orders_pending'] ?? 0} en cours',
        'icon': Icons.trending_up,
        'color': Colors.green,
      },
      {
        'title': 'Formations',
        'value': '${courses['total'] ?? 0}',
        'subtitle': '${courses['students'] ?? 0} étudiants',
        'icon': Icons.book,
        'color': Colors.teal,
      },
      {
        'title': 'Revenus',
        'value': '${NumberFormat('#,##0', 'fr_FR').format(financial['today_revenue'] ?? 0)} FCFA',
        'subtitle': 'Aujourd\'hui',
        'icon': Icons.money,
        'color': Colors.green,
      },
      {
        'title': 'Premium',
        'value': '${users['premium_requests'] ?? 0}',
        'subtitle': 'Demandes en attente',
        'icon': Icons.verified,
        'color': Colors.amber,
      },
      {
        'title': 'Signalements',
        'value': '${reports['pending'] ?? 0}',
        'subtitle': '${reports['resolved'] ?? 0} résolus',
        'icon': Icons.flag,
        'color': Colors.red,
      },
    ];

    final card = cards[index];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                card['icon'] as IconData,
                color: card['color'] as Color,
                size: 20,
              ),
              Text(
                card['subtitle'] as String,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 9,
                ),
              ),
            ],
          ),
          Text(
            card['value'] as String,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          Text(
            card['title'] as String,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppConstants.primaryColor,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
