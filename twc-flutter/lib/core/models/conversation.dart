import 'user.dart';
import 'message.dart';

class Conversation {
  final String id;
  final User user;
  final Message? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isArchived;
  final bool isBlocked;
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.user,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    required this.isArchived,
    required this.isBlocked,
    required this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    // Laravel renvoie les id en nombre (int), pas en String : cast sûr avec .toString()
    id: json['id'].toString(),
    // Le backend expose 'other_user' (calculé côté serveur), pas 'user'
    user: User.fromJson(json['other_user'] ?? json['user']),
    lastMessage: json['last_message'] != null
        ? Message.fromJson(json['last_message'])
        : null,
    lastMessageAt: DateTime.tryParse(json['last_message_at'] ?? ''),
    unreadCount: json['unread_count'] ?? 0,
    isArchived: json['is_archived'] ?? false,
    isBlocked: json['is_blocked'] ?? false,
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}
