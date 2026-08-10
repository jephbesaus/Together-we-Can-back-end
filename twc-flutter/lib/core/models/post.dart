import 'user.dart';

class Post {
  final String id;
  final String userId;
  final User user;
  final String content;
  final String mediaType;
  final List<String> mediaUrls;
  final bool isAnnouncement;
  final bool isStory;
  int likesCount;
  int commentsCount;
  int sharesCount;
  final int viewsCount;
  final DateTime createdAt;
  bool isLikedByUser;

  Post({
    required this.id,
    required this.userId,
    required this.user,
    required this.content,
    required this.mediaType,
    required this.mediaUrls,
    required this.isAnnouncement,
    required this.isStory,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.viewsCount,
    required this.createdAt,
    required this.isLikedByUser,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    // Laravel renvoie les id en nombre (int), pas en String : cast sûr avec .toString()
    id: json['id'].toString(),
    userId: json['user_id'].toString(),
    user: User.fromJson(json['user']),
    content: json['content'] ?? '',
    mediaType: json['media_type'] ?? 'text',
    mediaUrls: json['media_urls'] != null
        ? List<String>.from(json['media_urls'])
        : [],
    isAnnouncement: json['is_announcement'] ?? false,
    isStory: json['is_story'] ?? false,
    likesCount: json['likes_count'] ?? 0,
    commentsCount: json['comments_count'] ?? 0,
    sharesCount: json['shares_count'] ?? 0,
    viewsCount: json['views_count'] ?? 0,
    createdAt: DateTime.parse(json['created_at']),
    isLikedByUser: json['is_liked_by_user'] ?? false,
  );
}
