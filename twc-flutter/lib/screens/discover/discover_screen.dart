import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/models/post.dart';
import '../../widgets/story_widget.dart';
import '../../widgets/post_widget.dart';
import 'create_post_screen.dart';
import '../notification/notification_screen.dart';
import '../search/search_screen.dart';
import '../../widgets/app_drawer.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final ApiService _api = Get.find<ApiService>();
  List<Post> _posts = [];
  List<Post> _stories = [];
  bool _isLoading = true;
  bool _hasMore = false;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoading) {
        _loadPosts(page: _currentPage + 1);
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadStories(),
      _loadPosts(page: 1),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadStories() async {
    try {
      final response = await _api.get('/posts/stories');
      if (response['success']) {
        setState(() {
          _stories = (response['data']['stories'] as List)
              .map((item) => Post.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading stories: $e');
    }
  }

  Future<void> _loadPosts({int page = 1}) async {
    try {
      final response = await _api.get('/posts/feed', params: {
        'page': page,
        'limit': 20,
      });

      if (response['success']) {
        final newPosts = (response['data']['posts'] as List)
            .map((item) => Post.fromJson(item))
            .toList();

        setState(() {
          if (page == 1) {
            _posts = newPosts;
          } else {
            _posts.addAll(newPosts);
          }
          _currentPage = page;
          _hasMore = response['data']['has_more'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading posts: $e');
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppConstants.primaryColor,
                      image: const DecorationImage(
                        image: AssetImage('assets/images/logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Together We Can',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => Get.toNamed('/search'),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => Get.toNamed('/notifications'),
                ),
              ],
            ),

            // Stories
            SliverToBoxAdapter(
              child: _stories.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      height: 120,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _stories.length,
                        itemBuilder: (context, index) {
                          return StoryWidget(
                            post: _stories[index],
                            allStories: _stories,
                            index: index,
                          );
                        },
                      ),
                    ),
            ),

            // Posts
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == _posts.length) {
                      if (_isLoading && _posts.isNotEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (_hasMore) {
                        return const SizedBox.shrink();
                      }
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('— Fin du flux —'),
                        ),
                      );
                    }

                    final post = _posts[index];
                    return PostWidget(
                      post: post,
                      onLike: () => _handleLike(post),
                      onComment: () => _openComments(post),
                      onShare: () => _handleShare(post),
                      onReport: () => _handleReport(post),
                      onDelete: () => _handleDelete(post),
                    );
                  },
                  childCount: _posts.length + 1,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const CreatePostScreen());
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _handleLike(Post post) async {
    try {
      final response = await _api.post('/posts/${post.id}/like');
      if (response['success']) {
        setState(() {
          post.isLikedByUser = response['data']['liked'];
          post.likesCount = response['data']['likes_count'];
        });
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'aimer cette publication.');
    }
  }

  void _openComments(Post post) {
    Get.toNamed('/comments', arguments: post);
  }

  Future<void> _handleShare(Post post) async {
    try {
      final response = await _api.post('/posts/${post.id}/share');
      if (response['success']) {
        setState(() {
          post.sharesCount = response['data']['shares_count'];
        });
        Get.snackbar('Partagé', 'Publication partagée avec succès.');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de partager.');
    }
  }

  Future<void> _handleDelete(Post post) async {
    final confirm = await Get.dialog(
      AlertDialog(
        title: const Text('Supprimer la publication'),
        content: const Text('Voulez-vous vraiment supprimer cette publication ?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Annuler')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final response = await _api.delete('/posts/${post.id}');
      if (response['success']) {
        setState(() => _posts.removeWhere((p) => p.id == post.id));
        Get.snackbar('Succès', 'Publication supprimée.');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de supprimer.');
    }
  }

  Future<void> _handleReport(Post post) async {
    final reasonController = TextEditingController();

    final reason = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Signaler cette publication'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Décrivez le problème...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Get.back(result: reasonController.text.trim()),
            child: const Text('Signaler'),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        final response = await _api.post('/posts/${post.id}/report', data: {
          'reason': reason,
        });
        if (response['success']) {
          Get.snackbar(
            'Signalement envoyé',
            'Notre équipe va examiner cette publication.',
          );
        } else {
          Get.snackbar(
            'Erreur',
            ApiService.extractErrorMessage(response['error'], fallback: 'Impossible de signaler.'),
          );
        }
      } catch (e) {
        Get.snackbar('Erreur', 'Impossible de signaler.');
      }
    }
  }
}
