import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app/theme.dart';
import 'app/routes.dart';
import 'app/constants.dart';
import 'core/services/fcm_service.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/controllers/notification_controller.dart';
import 'core/controllers/theme_controller.dart';
import 'core/controllers/locale_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put(ApiService(), permanent: true);
  Get.put(AuthService(), permanent: true);
  Get.put(NotificationController(), permanent: true);
  Get.put(ThemeController(), permanent: true);
  Get.put(LocaleController(), permanent: true);

  // Surveillance de la connexion : affiche une modale "pas de connexion
  // internet" dès que le réseau disparaît (style Facebook).
  final connectivity = Get.put(ConnectivityService(), permanent: true);
  connectivity.init();

  // Deep links (retour Chariow après paiement)
  Get.put(DeepLinkService(), permanent: true)..init();

  // L'app démarre immédiatement, sans attendre Firebase/FCM.
  // Si Firebase n'est pas configuré côté Android (google-services.json manquant,
  // plugin Gradle absent, etc.), ces appels ne doivent JAMAIS empêcher l'app
  // de s'afficher — d'où le lancement en arrière-plan avec timeout de sécurité.
  runApp(const MyApp());

  _initFirebaseAndFcmInBackground();
  _checkForUpdates();
}

Future<void> _initFirebaseAndFcmInBackground() async {
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 8));
    final fcmService = FCMService();
    await fcmService.init().timeout(const Duration(seconds: 8));
  } catch (e) {
    print('Firebase/FCM init error (non-bloquant, app déjà lancée): $e');
  }
}

Future<void> _checkForUpdates() async {
  try {
    final api = Get.find<ApiService>();
    final response = await api.get('/app/version');
    if (response['success'] && response['data']['available'] == true) {
      final serverVersion = response['data']['version'] ?? '';
      if (serverVersion != AppConstants.appVersion && serverVersion.isNotEmpty) {
        Future.delayed(const Duration(seconds: 5), () {
          Get.dialog(
            AlertDialog(
              title: const Text('Mise à jour disponible'),
              content: Text('Version $serverVersion disponible.\n${response['data']['release_notes'] ?? ''}'),
              actions: [
                TextButton(onPressed: () => Get.back(), child: const Text('Plus tard')),
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                    final url = response['data']['download_url'];
                    if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  },
                  child: const Text('Mettre à jour'),
                ),
              ],
            ),
          );
        });
      }
    }
  } catch (_) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final localeController = Get.find<LocaleController>();

    return Obx(() => GetMaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode.value,
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      getPages: AppRoutes.routes,
      defaultTransition: Transition.fadeIn,
      translations: AppTranslations(),
      locale: localeController.locale.value,
      fallbackLocale: const Locale('fr', 'FR'),
    ));
  }
}

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'fr': {
      'app_name': 'Together We Can',
      'discover': 'Découvrir',
      'messages': 'Messages',
      'network': 'Réseau',
      'profile': 'Profil',
      'publish': 'Publier',
      'login': 'Se connecter',
      'register': 'S\'inscrire',
      'my_account': 'Mon compte',
      'my_profile': 'Mon profil',
      'edit_profile': 'Modifier le profil',
      'security': 'Sécurité',
      'change_password': 'Changer le mot de passe',
      'two_factor_auth': 'Authentification à 2 facteurs',
      'active_sessions': 'Sessions actives',
      'appearance': 'Apparence',
      'light_mode': 'Mode clair',
      'dark_mode': 'Mode sombre',
      'auto_mode': 'Automatique',
      'language': 'Langue',
      'wallet': 'Portefeuille',
      'marketplace': 'Marketplace',
      'courses': 'Formations',
      'boost': 'Clic-Boost',
      'premium': 'Together Mode Premium',
      'settings': 'Paramètres',
      'logout': 'Se déconnecter',
      'download_app': 'Télécharger l\'application',
      'about': 'À propos',
      'coming_soon': 'Bientôt disponible',
    },
    'en': {
      'app_name': 'Together We Can',
      'discover': 'Discover',
      'messages': 'Messages',
      'network': 'Network',
      'profile': 'Profile',
      'publish': 'Publish',
      'login': 'Login',
      'register': 'Register',
      'my_account': 'My account',
      'my_profile': 'My profile',
      'edit_profile': 'Edit profile',
      'security': 'Security',
      'change_password': 'Change password',
      'two_factor_auth': 'Two-factor authentication',
      'active_sessions': 'Active sessions',
      'appearance': 'Appearance',
      'light_mode': 'Light mode',
      'dark_mode': 'Dark mode',
      'auto_mode': 'Automatic',
      'language': 'Language',
      'wallet': 'Wallet',
      'marketplace': 'Marketplace',
      'courses': 'Courses',
      'boost': 'Clic-Boost',
      'premium': 'Together Mode Premium',
      'settings': 'Settings',
      'logout': 'Log out',
      'download_app': 'Download the app',
      'about': 'About',
      'coming_soon': 'Coming soon',
    },
  };
}
