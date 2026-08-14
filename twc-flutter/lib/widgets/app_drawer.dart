import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app/constants.dart';
import '../core/services/api_service.dart';
import '../core/services/auth_service.dart';
import '../core/services/media_service.dart';
import '../core/models/user.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/marketplace/marketplace_screen.dart';
import '../screens/courses/courses_screen.dart';
import '../screens/boost_home_screen.dart';
import '../screens/menu/premium_screen.dart';
import '../screens/menu/marketing_screen.dart';
import '../screens/menu/announcements_screen.dart';
import '../screens/menu/support_screen.dart';
import '../screens/menu/settings_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_activation_screen.dart';
import 'verified_badge.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final ApiService _api = Get.find<ApiService>();
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final response = await _api.get('/user/profile');
      if (response['success']) {
        setState(() => _user = User.fromJson(response['data']['user']));
      }
    } catch (e) {
      print('Error loading user for drawer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // En-tête profil
            InkWell(
              onTap: () {
                Get.back();
                Get.to(() => const ProfileScreen());
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: _user?.profilePhoto != null
                          ? CachedNetworkImageProvider(
                              MediaService.resolveUrl(_user!.profilePhoto!)!)
                          : null,
                      backgroundColor: Colors.grey[300],
                      child: _user?.profilePhoto == null
                          ? Text(
                              _user != null && _user!.name.isNotEmpty
                                  ? _user!.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _user?.name ?? '...',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (_user?.isPremium == true) ...[
                                const SizedBox(width: 4),
                                const VerifiedBadge(),
                              ],
                            ],
                          ),
                          Text(
                            'Voir mon profil',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _item(Icons.person_outline, 'Mon profil', () {
                    Get.back();
                    Get.to(() => const ProfileScreen());
                  }),
                  _item(Icons.edit_outlined, 'Modifier le profil', () {
                    Get.back();
                    Get.to(() => const EditProfileScreen());
                  }),
                  const Divider(),
                  _item(Icons.account_balance_wallet_outlined, 'Portefeuille', () {
                    Get.back();
                    Get.to(() => const WalletScreen());
                  }),
                  _item(Icons.shopping_bag_outlined, 'Marketplace', () {
                    Get.back();
                    Get.to(() => const MarketplaceScreen());
                  }),
                  _item(Icons.school_outlined, 'Formations', () {
                    Get.back();
                    Get.to(() => const CoursesScreen());
                  }),
                  _item(Icons.trending_up, 'Clic-Boost', () {
                    Get.back();
                    Get.to(() => const BoostHomeScreen());
                  }),
                  _item(Icons.verified_outlined, 'Together Mode Premium', () {
                    Get.back();
                    Get.to(() => const PremiumScreen());
                  }),
                  const Divider(),
                  _item(Icons.campaign_outlined, 'Marketing', () {
                    Get.back();
                    Get.to(() => const MarketingScreen());
                  }),
                  _item(Icons.newspaper_outlined, 'Actualités', () {
                    Get.back();
                    Get.to(() => const AnnouncementsScreen());
                  }),
                  _item(Icons.help_outline, 'Support & Aide', () {
                    Get.back();
                    Get.to(() => const SupportScreen());
                  }),
                  const Divider(),
                  if (_user?.email == AppConstants.adminEmail)
                    _item(Icons.admin_panel_settings, 'Administration', () {
                      Get.back();
                      Get.to(() => const AdminActivationScreen());
                    }),
                  _item(Icons.settings_outlined, 'Paramètres', () {
                    Get.back();
                    Get.to(() => const SettingsScreen());
                  }),
                ],
              ),
            ),
            const Divider(height: 1),
            _item(Icons.logout, 'Se déconnecter', () async {
              Get.back();
              await Get.find<AuthService>().logout();
              Get.offAll(() => const LoginScreen());
            }, color: Colors.red),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppConstants.primaryColor),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
      dense: true,
    );
  }
}
