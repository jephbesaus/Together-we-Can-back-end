import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _api = Get.find<ApiService>();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/notifications');
      if (response['success']) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(
            response['data']['notifications'] ?? [],
          );
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _markAllAsRead() async {
    try {
      await _api.put('/notifications/read-all');
      setState(() {
        for (var n in _notifications) {
          n['is_read'] = true;
        }
      });
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  int get _unreadCount => _notifications.where((n) => n['is_read'] == false).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Tout lire'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune notification',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vous serez notifié des activités importantes',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) => _buildNotificationCard(_notifications[index], isDark),
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, bool isDark) {
    final isRead = notification['is_read'] ?? false;
    final type = notification['type'] ?? '';
    final typeColor = notification['type_color'] != null
        ? Color(int.parse(notification['type_color'].replaceFirst('#', '0xFF')))
        : AppConstants.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isRead
            ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
            : typeColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead
              ? (isDark ? Colors.grey[800]! : Colors.grey[200]!)
              : typeColor.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIcon(notification['type_icon']),
                color: typeColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['title'] ?? notification['message'] ?? '',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'] ?? '',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        notification['time_ago'] ??
                            timeago.format(
                              DateTime.parse(notification['created_at']),
                              locale: 'fr',
                            ),
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Unread dot
            if (!isRead)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(left: 8, top: 4),
                decoration: BoxDecoration(
                  color: typeColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String? icon) {
    switch (icon) {
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'favorite':
        return Icons.favorite_border;
      case 'comment':
        return Icons.comment_outlined;
      case 'share':
        return Icons.share_outlined;
      case 'person_add':
        return Icons.person_add_outlined;
      case 'verified':
        return Icons.verified_outlined;
      case 'cancel':
        return Icons.cancel_outlined;
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'trending_up':
        return Icons.trending_up;
      case 'check_circle':
        return Icons.check_circle_outline;
      case 'campaign':
        return Icons.campaign_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'block':
        return Icons.block;
      case 'check':
        return Icons.check;
      case 'send':
        return Icons.send_outlined;
      case 'download':
        return Icons.download_outlined;
      case 'payment_approved':
        return Icons.check_circle;
      case 'payment_rejected':
        return Icons.cancel;
      default:
        return Icons.notifications_outlined;
    }
  }
}
