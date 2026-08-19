import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import '../app/constants.dart';
import '../core/models/post.dart';
import '../core/services/media_service.dart';
import '../screens/profile/user_profile_screen.dart';
import 'video_player_widget.dart';
import 'verified_badge.dart';

class PostWidget extends StatelessWidget {
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onReport;
  final VoidCallback? onDelete;

  const PostWidget({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onReport,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: isDark ? 0 : 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Get.to(() => UserProfileScreen(userId: post.user.id)),
                  child: CircleAvatar(
                  radius: 22,
                  backgroundImage: post.user.profilePhoto != null
                      ? CachedNetworkImageProvider(MediaService.resolveUrl(post.user.profilePhoto) ?? post.user.profilePhoto!)
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: post.user.profilePhoto == null
                      ? Text(
                          post.user.name.isNotEmpty
                              ? post.user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => Get.to(() => UserProfileScreen(userId: post.user.id)),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (post.user.isPremium) ...[
                            const SizedBox(width: 4),
                            const VerifiedBadge(),
                          ],
                        ],
                      ),
                      Text(
                        timeago.format(post.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showOptions(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                post.content,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
          const SizedBox(height: 8),

          // Media
          if (post.mediaUrls.isNotEmpty) ...[
            _buildMedia(),
          ],

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                InkWell(
                  onTap: onLike,
                  child: Row(
                    children: [
                      Icon(
                        post.isLikedByUser
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: post.isLikedByUser ? Colors.red : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.likesCount > 0 ? '${post.likesCount}' : '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: onComment,
                  child: Row(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.commentsCount > 0 ? '${post.commentsCount}' : '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: onShare,
                  child: Row(
                    children: [
                      Icon(
                        Icons.share_outlined,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.sharesCount > 0 ? '${post.sharesCount}' : '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    final media = post.mediaUrls;

    if (media.length == 1) {
      if (post.mediaType == 'video') {
        return VideoPostPlayer(url: MediaService.resolveUrl(media.first) ?? media.first);
      }
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480, minHeight: 180),
        child: CachedNetworkImage(
          imageUrl: MediaService.resolveUrl(media.first) ?? media.first,
          fit: BoxFit.contain,
          width: double.infinity,
          placeholder: (context, url) => Container(
            height: 260,
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            height: 260,
            color: Colors.grey[200],
            child: const Icon(Icons.error, color: Colors.grey),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: media.length <= 2 ? media.length : 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: media.length > 6 ? 6 : media.length,
      itemBuilder: (context, index) {
        if (index == 5 && media.length > 6) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: MediaService.resolveUrl(media[index]) ?? media[index],
                fit: BoxFit.cover,
              ),
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Text(
                    '+${media.length - 6}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return CachedNetworkImage(
          imageUrl: MediaService.resolveUrl(media[index]) ?? media[index],
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.grey[300]),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.error),
          ),
        );
      },
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Signaler'),
              onTap: () {
                Navigator.pop(context);
                onReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copier le lien'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
