import 'package:get/get.dart';
import '../services/api_service.dart';

class NotificationController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final RxInt unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadUnreadCount();
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await _api.get('/notifications/unread-count');
      if (response['success']) {
        unreadCount.value = response['data']?['unread_count'] ?? 0;
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }
}
