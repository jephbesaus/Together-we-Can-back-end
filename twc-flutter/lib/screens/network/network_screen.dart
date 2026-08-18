import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/models/user.dart';
import '../profile/user_profile_screen.dart';
import '../../widgets/verified_badge.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = Get.find<ApiService>();
  late TabController _tabController;

  List<User> _followers = [];
  List<User> _following = [];
  List<User> _suggestions = [];
  Map<String, dynamic> _referralInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final followers = await _api.get('/follow/my-followers');
      final following = await _api.get('/follow/my-following');
      final suggestions = await _api.get('/follow/suggestions');
      final referral = await _api.get('/referrals/my-info');

      if (followers['success']) {
        setState(() {
          _followers = (followers['data']['followers'] as List)
              .map((item) => User.fromJson(item))
              .toList();
        });
      }

      if (following['success']) {
        setState(() {
          _following = (following['data']['following'] as List)
              .map((item) => User.fromJson(item))
              .toList();
        });
      }

      if (suggestions['success']) {
        setState(() {
          _suggestions = (suggestions['data']['suggestions'] as List)
              .map((item) => User.fromJson(item))
              .toList();
        });
      }

      if (referral['success']) {
        setState(() {
          _referralInfo = referral['data'] ?? {};
        });
      }
    } catch (e) {
      print('Error loading network data: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _handleFollow(User user) async {
    try {
      final response = await _api.post('/users/${user.id}/follow');
      if (response['success']) {
        setState(() {
          // Le backend renvoie la clé 'following', pas 'is_following'
          user.isFollowing = response['data']['following'];
        });
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de suivre cet utilisateur.');
    }
  }

  void _shareReferral() {
    final code = _referralInfo['referral_code'] ?? '';
    final link = _referralInfo['referral_link'] ?? '';
    Share.share(
      'Rejoins-moi sur Together We Can avec mon code de parrainage : $code\n'
      'Lien d\'inscription : $link\n\n'
      '1. Télécharge l\'application\n'
      '2. Crée ton compte\n'
      '3. Entre le code $code lors de l\'inscription\n'
      '4. Tu reçois 500 CDF automatiquement !\n\n'
      '🎁 Gagne 500 CDF par parrainage !',
    );
  }

  void _copyReferralCode() {
    final code = _referralInfo['referral_code'] ?? '';
    // Copy to clipboard
    Get.snackbar('Copié !', 'Code de parrainage copié : $code');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  title: const Text('Réseau'),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Referral card
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
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
                            const Row(
                              children: [
                                Text(
                                  '🎁 Parrainage',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  '500 CDF / parrain',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gagnez de l\'argent en invitant vos amis !',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Code: ${_referralInfo['referral_code'] ?? ''}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _copyReferralCode,
                                  icon: const Icon(
                                    Icons.copy,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _shareReferral,
                                  icon: const Icon(
                                    Icons.share,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  // Le backend renvoie 'referral_earnings', pas 'total_earnings'
                                  'Total gagné: ${_referralInfo['referral_earnings'] ?? 0} CDF',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${_referralInfo['referral_count'] ?? 0} parrainés',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    child: Container(
                      color: theme.scaffoldBackgroundColor,
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: AppConstants.primaryColor,
                        labelColor: AppConstants.primaryColor,
                        unselectedLabelColor: Colors.grey,
                        tabs: const [
                          Tab(text: 'Abonnés'),
                          Tab(text: 'Abonnements'),
                          Tab(text: 'Suggestions'),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUserList(_followers),
                      _buildUserList(_following),
                      _buildUserList(_suggestions),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUserList(List<User> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun utilisateur',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            onTap: () => Get.to(() => UserProfileScreen(userId: user.id)),
            leading: CircleAvatar(
              radius: 26,
              backgroundImage: user.profilePhoto != null
                  ? CachedNetworkImageProvider(user.profilePhoto!)
                  : null,
              backgroundColor: Colors.grey[300],
              child: user.profilePhoto == null
                  ? Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Row(
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (user.isPremium) ...[
                  const SizedBox(width: 4),
                  const VerifiedBadge(),
                ],
              ],
            ),
            subtitle: Text(
              user.bio ?? '${user.followersCount} abonnés',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            trailing: ElevatedButton(
              onPressed: () => _handleFollow(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: user.isFollowing == true
                    ? Colors.grey[300]
                    : AppConstants.primaryColor,
                foregroundColor: user.isFollowing == true
                    ? Colors.black87
                    : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(user.isFollowing == true ? 'Suivi' : 'Suivre'),
            ),
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate({required this.child});

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
