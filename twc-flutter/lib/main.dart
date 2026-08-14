import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/theme.dart';
import 'app/routes.dart';
import 'app/constants.dart';
import 'core/services/fcm_service.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/connectivity_service.dart';
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

  // L'app démarre immédiatement, sans attendre Firebase/FCM.
  // Si Firebase n'est pas configuré côté Android (google-services.json manquant,
  // plugin Gradle absent, etc.), ces appels ne doivent JAMAIS empêcher l'app
  // de s'afficher — d'où le lancement en arrière-plan avec timeout de sécurité.
  runApp(const MyApp());

  _initFirebaseAndFcmInBackground();
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      getPages: AppRoutes.routes,
      defaultTransition: Transition.fadeIn,
      translations: AppTranslations(),
      locale: const Locale('fr', 'FR'),
      fallbackLocale: const Locale('fr', 'FR'),
    );
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
