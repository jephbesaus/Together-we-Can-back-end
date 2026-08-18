import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/user.dart';
import '../../core/models/post.dart';
import '../../widgets/post_widget.dart';
import 'edit_profile_screen.dart';
import '../auth/login_screen.dart';
import '../menu/settings_screen.dart';
import '../admin/admin_activation_screen.dart';
import '../../widgets/verified_badge.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = Get.find<ApiService>();
  User? _user;
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final response = await _api.get('/user/profile');
      if (response['success']) {
        setState(() {
          _user = User.fromJson(response['data']['user']);
          _posts = (response['data']['posts'] as List?)
              ?.map((item) => Post.fromJson(item))
              .toList() ?? [];
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Profil non trouvé'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.offAll(() => const LoginScreen()),
                child: const Text('Se reconnecter'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            title: const Text('Mon Profil'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Get.to(() => const SettingsScreen()),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Profile header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _user!.profilePhoto != null
                            ? CachedNetworkImageProvider(_user!.profilePhoto!)
                            : null,
                        backgroundColor: Colors.grey[300],
                        child: _user!.profilePhoto == null
                            ? Text(
                                _user!.name.isNotEmpty
                                    ? _user!.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 32),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _user!.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_user!.isPremium) ...[
                            const SizedBox(width: 6),
                            const VerifiedBadge(size: 20),
                          ],
                        ],
                      ),
                      if (_user!.isPremium) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Premium',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_user!.bio != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _user!.bio!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            _posts.length.toString(),
                            'Publications',
                          ),
                          _buildStatItem(
                            _user!.followersCount.toString(),
                            'Abonnés',
                          ),
                          _buildStatItem(
                            _user!.followingCount.toString(),
                            'Abonnements',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Get.to(() => const EditProfileScreen()),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppConstants.primaryColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Modifier le profil'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_user?.email == AppConstants.adminEmail) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Get.to(() => const AdminActivationScreen()),
                                icon: const Icon(Icons.admin_panel_settings),
                                label: const Text('Administration'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppConstants.primaryColor,
                                  side: BorderSide(color: AppConstants.primaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => _showLogoutDialog(),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Se déconnecter'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Posts
                if (_posts.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.article_outlined, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Mes publications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      return PostWidget(
                        post: post,
                        onLike: () {},
                        onComment: () {},
                        onShare: () {},
                        onReport: () {},
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await Get.find<AuthService>().logout();
              Get.offAll(() => const LoginScreen());
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
