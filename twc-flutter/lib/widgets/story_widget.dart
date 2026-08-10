import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app/constants.dart';
import '../core/models/post.dart';
import '../screens/discover/story_viewer_screen.dart';

class StoryWidget extends StatelessWidget {
  final Post post;
  final List<Post> allStories;
  final int index;

  const StoryWidget({
    super.key,
    required this.post,
    this.allStories = const [],
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final stories = allStories.isNotEmpty ? allStories : [post];
        Get.to(() => StoryViewerScreen(stories: stories, initialIndex: index));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppConstants.primaryColor, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: post.user.profilePhoto != null
                    ? CachedNetworkImageProvider(post.user.profilePhoto!)
                    : null,
                backgroundColor: Colors.grey[300],
                child: post.user.profilePhoto == null
                    ? Text(
                        post.user.name.isNotEmpty
                            ? post.user.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 20),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 60,
              child: Text(
                post.user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
