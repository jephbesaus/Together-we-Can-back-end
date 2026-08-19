import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/media_service.dart';
import '../../core/models/conversation.dart';
import 'chat_screen.dart';
import '../../widgets/verified_badge.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ApiService _api = Get.find<ApiService>();
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshSilently());
  }

  Future<void> _refreshSilently() async {
    if (!mounted) return;
    try {
      final response = await _api.get('/messages/conversations');
      if (response['success'] && mounted) {
        final conversations = (response['data']['conversations'] as List)
            .map((item) => Conversation.fromJson(item))
            .toList();
        setState(() => _conversations = conversations);
      }
    } catch (_) {}
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/messages/conversations');
      if (response['success']) {
        setState(() {
          _conversations = (response['data']['conversations'] as List)
              .map((item) => Conversation.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading conversations: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _refresh() async {
    await _loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _conversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.message_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Aucun message', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text('Commencez une conversation avec un membre.', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        floating: true,
                        pinned: true,
                        backgroundColor: theme.scaffoldBackgroundColor,
                        title: const Text('Messages'),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () => Get.toNamed('/search-messages'),
                          ),
                        ],
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final conversation = _conversations[index];
                            return _buildConversationTile(conversation);
                          },
                          childCount: _conversations.length,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = conversation.user;
    final photoUrl = user.profilePhoto != null ? MediaService.resolveUrl(user.profilePhoto) : null;

    return InkWell(
      onTap: () {
        Get.to(() => ChatScreen(conversation: conversation));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: conversation.unreadCount > 0
              ? (isDark ? const Color(0xFF1A2E1A) : const Color(0xFFE8F5E9))
              : null,
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
              backgroundColor: Colors.grey[300],
              child: photoUrl == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
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
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (user.isPremium) ...[
                              const SizedBox(width: 4),
                              const VerifiedBadge(size: 14),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        conversation.lastMessageAt != null ? timeago.format(conversation.lastMessageAt!) : '',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage?.content ?? 'Aucun message',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: conversation.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                            fontWeight: conversation.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (conversation.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppConstants.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
