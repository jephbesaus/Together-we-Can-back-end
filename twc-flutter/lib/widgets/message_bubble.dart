import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../app/constants.dart';
import '../core/models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwnMessage;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isOwnMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: message.sender?.profilePhoto != null
                  ? CachedNetworkImageProvider(message.sender!.profilePhoto!)
                  : null,
              child: message.sender?.profilePhoto == null
                  ? Text(
                      message.sender?.name.isNotEmpty == true
                          ? message.sender!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isOwnMessage
                    ? AppConstants.primaryColor
                    : theme.brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
                        : Colors.white,
                borderRadius: BorderRadius.circular(16).copyWith(
                  topLeft: isOwnMessage
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  topRight: isOwnMessage
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.mediaUrl != null) ...[
                    if (message.mediaType == 'image')
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: message.mediaUrl!,
                          width: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 150,
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 150,
                            color: Colors.grey[200],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                    if (message.mediaType == 'video')
                      Container(
                        height: 150,
                        width: 200,
                        color: Colors.black,
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                  ],
                  if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isOwnMessage ? Colors.white : null,
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeago.format(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isOwnMessage
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey[600],
                        ),
                      ),
                      if (isOwnMessage) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead
                              ? AppConstants.primaryColor
                              : Colors.grey[400],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isOwnMessage) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
