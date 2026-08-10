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
        for (var notification in _notifications) {
          notification['is_read'] = true;
        }
      });
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          if (_notifications.where((n) => n['is_read'] == false).isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Tout lire'),
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
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune notification',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final isRead = notification['is_read'] ?? false;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isRead
                            ? (isDark ? const Color(0xFF0B0B0B) : Colors.white)
                            : (isDark
                                ? const Color(0xFF1A2A1A)
                                : const Color(0xFFF0FAF0)),
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFFF0F0F0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (notification['type_color'] != null
                                      ? Color(
                                          int.parse(
                                            notification['type_color']
                                                .replaceFirst('#', '0xFF'),
                                          ),
                                        )
                                      : AppConstants.primaryColor)
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIcon(notification['type_icon']),
                              color: notification['type_color'] != null
                                  ? Color(
                                      int.parse(
                                        notification['type_color']
                                            .replaceFirst('#', '0xFF'),
                                      ),
                                    )
                                  : AppConstants.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification['title'] ?? notification['message'],
                                  style: TextStyle(
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification['message'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification['time_ago'] ??
                                      timeago.format(
                                        DateTime.parse(notification['created_at']),
                                      ),
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppConstants.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  IconData _getIcon(String? icon) {
    switch (icon) {
      case 'chat':
        return Icons.chat;
      case 'favorite':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'share':
        return Icons.share;
      case 'person_add':
        return Icons.person_add;
      case 'verified':
        return Icons.verified;
      case 'cancel':
        return Icons.cancel;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'trending_up':
        return Icons.trending_up;
      case 'check_circle':
        return Icons.check_circle;
      case 'campaign':
        return Icons.campaign;
      case 'payment':
        return Icons.payment;
      case 'school':
        return Icons.school;
      case 'block':
        return Icons.block;
      case 'check':
        return Icons.check;
      case 'send':
        return Icons.send;
      case 'download':
        return Icons.download;
      default:
        return Icons.notifications;
    }
  }
}
