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
import '../screens/marketplace/add_product_screen.dart';
import '../screens/marketplace/product_detail_screen.dart';
import '../screens/marketplace/orders_screen.dart';
import '../screens/courses/courses_screen.dart';
import '../screens/courses/search_courses_screen.dart';
import '../screens/courses/course_detail_screen.dart';
import '../screens/discover/comments_screen.dart';
import '../screens/boost_home_screen.dart';
import '../screens/boost/boost_orders_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/wallet/savings_screen.dart';
import '../screens/wallet/transactions_screen.dart';
import '../screens/wallet/transfer_screen.dart';
import '../screens/messages/search_messages_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_news_screen.dart';
import '../screens/course/lesson_player_screen.dart';
import '../screens/wallet/withdraw_screen.dart';
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

  static const addProduct = '/add-product';
  static const productDetail = '/product-detail';
  static const orders = '/orders';
  static const searchCourses = '/search-courses';
  static const courseDetail = '/course-detail';
  static const comments = '/comments';
  static const boostOrders = '/boost-orders';
  static const boostHistory = '/boost-history';
  static const savings = '/savings';
  static const transactions = '/transactions';
  static const searchMessages = '/search-messages';
  static const lessonPlayer = '/course/lesson';
  static const withdraw = '/wallet/withdraw';
  static const adminNews = '/admin/news';

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

    GetPage(name: addProduct, page: () => const AddProductScreen()),
    GetPage(name: productDetail, page: () => ProductDetailScreen(productId: Get.arguments as String)),
    GetPage(name: orders, page: () => const OrdersScreen()),
    GetPage(name: searchCourses, page: () => const SearchCoursesScreen()),
    GetPage(name: courseDetail, page: () => CourseDetailScreen(courseId: Get.arguments as String)),
    GetPage(name: comments, page: () => CommentsScreen(post: Get.arguments)),
    GetPage(name: boostOrders, page: () => const BoostOrdersScreen()),
    GetPage(name: boostHistory, page: () => const BoostOrdersScreen(title: 'Historique des commandes')),
    GetPage(name: savings, page: () => const SavingsScreen()),
    GetPage(name: transactions, page: () => const TransactionsScreen()),
    GetPage(name: searchMessages, page: () => const SearchMessagesScreen()),
    GetPage(name: lessonPlayer, page: () {
      final args = Get.arguments as Map<String, dynamic>;
      return LessonPlayerScreen(
        courseId: args['courseId'],
        sectionId: args['sectionId'],
        lessonId: args['lessonId'],
        lessonTitle: args['lessonTitle'] ?? 'Leçon',
        lessonType: args['lessonType'] ?? 'text',
        videoUrl: args['videoUrl'],
        content: args['content'],
        questions: args['questions'] != null
            ? List<Map<String, dynamic>>.from(args['questions'])
            : null,
      );
    }),
    GetPage(name: withdraw, page: () => const WithdrawScreen()),
    GetPage(name: adminNews, page: () => const AdminNewsScreen()),
  ];
}
