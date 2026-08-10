import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/models/post.dart';
import '../../widgets/post_widget.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final ApiService _api = Get.find<ApiService>();
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/user/profile');
      if (response['success']) {
        setState(() {
          _posts = (response['data']['posts'] as List? ?? [])
              .map((item) => Post.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading my posts: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _delete(Post post) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Supprimer cette publication ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await _api.delete('/posts/${post.id}');
        if (response['success']) {
          setState(() => _posts.removeWhere((p) => p.id == post.id));
          Get.snackbar('Succès', 'Publication supprimée.');
        }
      } catch (e) {
        Get.snackbar('Erreur', 'Erreur réseau.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Historique de mes publications'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? Center(
                  child: Text('Vous n\'avez pas encore publié.', style: TextStyle(color: Colors.grey[600])),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return Stack(
                      children: [
                        PostWidget(
                          post: post,
                          onLike: () {},
                          onComment: () {},
                          onShare: () {},
                          onReport: () {},
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                              onPressed: () => _delete(post),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
