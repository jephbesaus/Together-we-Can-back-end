import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/controllers/theme_controller.dart';
import '../../core/controllers/locale_controller.dart';
import '../auth/login_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'my_posts_screen.dart';
import 'legal_content_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _api = Get.find<ApiService>();
  final ThemeController _themeController = Get.find<ThemeController>();
  final LocaleController _localeController = Get.find<LocaleController>();

  Map<String, dynamic>? _appVersionInfo;
  bool _checkingUpdate = false;

  // Préférences de notifications (stockage local pour l'instant — le filtrage
  // effectif côté serveur n'est pas encore implémenté sur le backend).
  bool _notifMessages = true;
  bool _notifLikes = true;
  bool _notifComments = true;
  bool _notifFollowers = true;
  bool _notifPromotions = true;

  Future<void> _checkAppVersion() async {
    setState(() => _checkingUpdate = true);
    try {
      final response = await _api.get('/app/version');
      if (response['success']) {
        setState(() => _appVersionInfo = response['data']);
      }
    } catch (e) {
      print('Error checking app version: $e');
    }
    setState(() => _checkingUpdate = false);
  }

  Future<void> _downloadApp() async {
    final apiBaseUrl = AppConstants.apiBaseUrl;
    final baseUrl = apiBaseUrl.replaceAll('/api', '');
    final downloadUrl = '$baseUrl/download';

    final uri = Uri.parse(downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Erreur', 'Impossible d\'ouvrir le lien de téléchargement.');
    }
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool isSaving = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe actuel'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nouveau mot de passe (min. 8)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirmer le nouveau mot de passe'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (newController.text.length < 8) {
                        Get.snackbar('Erreur', 'Le nouveau mot de passe doit faire au moins 8 caractères.');
                        return;
                      }
                      if (newController.text != confirmController.text) {
                        Get.snackbar('Erreur', 'Les mots de passe ne correspondent pas.');
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      try {
                        final response = await _api.post('/auth/change-password', data: {
                          'current_password': currentController.text,
                          'new_password': newController.text,
                          'new_password_confirmation': confirmController.text,
                        });

                        if (response['success']) {
                          Get.back();
                          Get.snackbar('Succès', 'Mot de passe modifié.');
                        } else {
                          Get.snackbar(
                            'Erreur',
                            ApiService.extractErrorMessage(response['error'], fallback: 'Échec du changement.'),
                          );
                        }
                      } catch (e) {
                        Get.snackbar('Erreur', 'Erreur réseau.');
                      }

                      setDialogState(() => isSaving = false);
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    Get.dialog(
      Obx(() => AlertDialog(
            title: const Text('Apparence'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('☀️ Mode clair'),
                  value: ThemeMode.light,
                  groupValue: _themeController.themeMode.value,
                  onChanged: (v) => _themeController.setThemeMode(v!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('🌙 Mode sombre'),
                  value: ThemeMode.dark,
                  groupValue: _themeController.themeMode.value,
                  onChanged: (v) => _themeController.setThemeMode(v!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('⚙️ Automatique (suit le système)'),
                  value: ThemeMode.system,
                  groupValue: _themeController.themeMode.value,
                  onChanged: (v) => _themeController.setThemeMode(v!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('Fermer')),
            ],
          )),
    );
  }

  void _showLanguageDialog() {
    Get.dialog(
      Obx(() => AlertDialog(
            title: const Text('Langue / Language'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('🇫🇷 Français'),
                  value: 'fr',
                  groupValue: _localeController.locale.value.languageCode,
                  onChanged: (v) => _localeController.setLocale(v!),
                ),
                RadioListTile<String>(
                  title: const Text('🇬🇧 English'),
                  value: 'en',
                  groupValue: _localeController.locale.value.languageCode,
                  onChanged: (v) => _localeController.setLocale(v!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('Fermer')),
            ],
          )),
    );
  }

  void _showNotificationSettings() {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Notifications'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Messages'),
                value: _notifMessages,
                onChanged: (v) => setDialogState(() => _notifMessages = v),
              ),
              SwitchListTile(
                title: const Text('J\'aime'),
                value: _notifLikes,
                onChanged: (v) => setDialogState(() => _notifLikes = v),
              ),
              SwitchListTile(
                title: const Text('Commentaires'),
                value: _notifComments,
                onChanged: (v) => setDialogState(() => _notifComments = v),
              ),
              SwitchListTile(
                title: const Text('Nouveaux abonnés'),
                value: _notifFollowers,
                onChanged: (v) => setDialogState(() => _notifFollowers = v),
              ),
              SwitchListTile(
                title: const Text('Promotions'),
                value: _notifPromotions,
                onChanged: (v) => setDialogState(() => _notifPromotions = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {});
                Get.back();
              },
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _sectionTitle('Profil'),
          _tile(
            icon: Icons.edit_outlined,
            title: 'Modifier le profil',
            subtitle: 'Nom, bio, photo, téléphone',
            onTap: () => Get.to(() => const EditProfileScreen()),
          ),
          _tile(
            icon: Icons.history,
            title: 'Historique de mes publications',
            subtitle: 'Voir et supprimer mes publications',
            onTap: () => Get.to(() => const MyPostsScreen()),
          ),
          const Divider(),

          _sectionTitle('Sécurité'),
          _tile(
            icon: Icons.lock_outline,
            title: 'Changer le mot de passe',
            onTap: _showChangePasswordDialog,
          ),
          const Divider(),

          _sectionTitle('Préférences'),
          _tile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: _showNotificationSettings,
          ),
          Obx(() => _tile(
                icon: Icons.brightness_6_outlined,
                title: 'Apparence',
                subtitle: _themeController.themeMode.value == ThemeMode.light
                    ? 'Clair'
                    : _themeController.themeMode.value == ThemeMode.dark
                        ? 'Sombre'
                        : 'Automatique',
                onTap: _showThemeDialog,
              )),
          Obx(() => _tile(
                icon: Icons.language_outlined,
                title: 'Langue',
                subtitle: _localeController.locale.value.languageCode == 'en'
                    ? 'English'
                    : 'Français',
                onTap: _showLanguageDialog,
              )),
          const Divider(),

          _sectionTitle('Application'),
          _tile(
            icon: Icons.download_outlined,
            title: 'Télécharger l\'application',
            subtitle: 'Obtenir le fichier APK (hors Play Store)',
            trailing: _checkingUpdate
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _downloadApp,
          ),
          _tile(
            icon: Icons.info_outline,
            title: 'Version de l\'application',
            subtitle: AppConstants.appVersion,
            onTap: () {},
          ),
          _tile(
            icon: Icons.description_outlined,
            title: 'Conditions d\'utilisation',
            onTap: () => Get.to(() => const LegalContentScreen(
                  title: 'Conditions d\'utilisation',
                  content: LegalContentScreen.terms,
                )),
          ),
          _tile(
            icon: Icons.privacy_tip_outlined,
            title: 'Politique de confidentialité',
            onTap: () => Get.to(() => const LegalContentScreen(
                  title: 'Politique de confidentialité',
                  content: LegalContentScreen.privacy,
                )),
          ),
          const Divider(),

          _tile(
            icon: Icons.logout,
            title: 'Se déconnecter',
            titleColor: Colors.red,
            onTap: () async {
              await Get.find<AuthService>().logout();
              Get.offAll(() => const LoginScreen());
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppConstants.primaryColor),
      title: Text(title, style: TextStyle(color: titleColor)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
