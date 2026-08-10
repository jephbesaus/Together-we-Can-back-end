import 'package:get/get.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_otp_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/notification/notification_screen.dart';
import '../screens/marketplace/marketplace_screen.dart';
import '../screens/courses/courses_screen.dart';
import '../screens/boost_home_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/wallet/transfer_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/menu/settings_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const verifyOtp = '/verify-otp';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const discover = '/discover';
  static const home = '/home';
  static const search = '/search';
  static const notifications = '/notifications';
  static const marketplace = '/marketplace';
  static const courses = '/courses';
  static const boost = '/boost';
  static const wallet = '/wallet';
  static const transfer = '/transfer';
  static const settings = '/settings';
  static const adminDashboard = '/admin/dashboard';

  static final routes = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: register, page: () => const RegisterScreen()),
    GetPage(name: verifyOtp, page: () => const VerifyOtpScreen()),
    GetPage(name: forgotPassword, page: () => const ForgotPasswordScreen()),
    GetPage(name: resetPassword, page: () => const ResetPasswordScreen()),
    // 'discover' et 'home' mènent tous les deux à la coquille principale
    // avec la barre de navigation (Découvrir / Messages / Réseau / Profil).
    GetPage(name: discover, page: () => const BottomNavBar()),
    GetPage(name: home, page: () => const BottomNavBar()),
    GetPage(name: search, page: () => const SearchScreen()),
    GetPage(name: notifications, page: () => const NotificationScreen()),
    GetPage(name: marketplace, page: () => const MarketplaceScreen()),
    GetPage(name: courses, page: () => const CoursesScreen()),
    GetPage(name: boost, page: () => const BoostHomeScreen()),
    GetPage(name: wallet, page: () => const WalletScreen()),
    GetPage(name: transfer, page: () => const TransferScreen()),
    GetPage(name: settings, page: () => const SettingsScreen()),
    GetPage(name: adminDashboard, page: () => const AdminDashboardScreen()),
  ];
}
