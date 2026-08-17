import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../core/models/post.dart';
import '../../core/services/api_service.dart';
import 'package:get/get.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Post> stories;
  final int initialIndex;

  const StoryViewerScreen({super.key, required this.stories, this.initialIndex = 0});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  final ApiService _api = Get.find<ApiService>();
  final Set<String> _viewedStories = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      });
    _trackStoryView(widget.stories[_currentIndex].id);
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _trackStoryView(String storyId) async {
    if (_viewedStories.contains(storyId)) return;
    _viewedStories.add(storyId);
    try {
      await _api.post('/posts/stories/$storyId/view');
    } catch (e) {
      // Silent fail - view tracking is non-critical
    }
  }

  void _next() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _trackStoryView(widget.stories[_currentIndex].id);
      _progressController.forward(from: 0);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _trackStoryView(widget.stories[_currentIndex].id);
      _progressController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final mediaUrls = story.mediaUrls;
    final hasImage = mediaUrls.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _previous();
          } else {
            _next();
          }
        },
        onLongPress: () => _progressController.stop(),
        onLongPressUp: () => _progressController.forward(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              CachedNetworkImage(
                imageUrl: mediaUrls.first,
                fit: BoxFit.cover,
              )
            else
              Container(
                color: const Color(0xFF00A86B),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(32),
                child: Text(
                  story.content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
            if (hasImage && story.content.isNotEmpty)
              Positioned(
                bottom: 60,
                left: 16,
                right: 16,
                child: Text(
                  story.content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16, shadows: [
                    Shadow(blurRadius: 6, color: Colors.black),
                  ]),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  Row(
                    children: List.generate(widget.stories.length, (i) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: i == _currentIndex
                              ? AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (context, child) => FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _progressController.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                )
                              : i < _currentIndex
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    )
                                  : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[400],
                          backgroundImage: story.user.profilePhoto != null
                              ? CachedNetworkImageProvider(story.user.profilePhoto!)
                              : null,
                          child: story.user.profilePhoto == null
                              ? Text(story.user.name.isNotEmpty ? story.user.name[0].toUpperCase() : '?')
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            story.user.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
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
