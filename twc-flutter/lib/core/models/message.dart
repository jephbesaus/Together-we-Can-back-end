import 'user.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final User? sender;
  final User? receiver;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final String timeAgo;
  final bool isSentByUser;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    this.sender,
    this.receiver,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.timeAgo,
    required this.isSentByUser,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    // Laravel renvoie les id en nombre (int), pas en String : cast sûr avec .toString()
    id: json['id'].toString(),
    conversationId: json['conversation_id']?.toString() ?? '',
    senderId: json['sender_id'].toString(),
    receiverId: json['receiver_id'].toString(),
    sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
    receiver: json['receiver'] != null ? User.fromJson(json['receiver']) : null,
    content: json['content'] ?? '',
    mediaUrl: json['media_url'],
    mediaType: json['media_type'],
    isRead: json['is_read'] ?? false,
    readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    createdAt: DateTime.parse(json['created_at']),
    timeAgo: json['time_ago'] ?? '',
    isSentByUser: json['is_sent_by_user'] ?? false,
  );
}
