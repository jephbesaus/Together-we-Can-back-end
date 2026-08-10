import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class AdminPostsScreen extends StatefulWidget {
  const AdminPostsScreen({super.key});

  @override
  State<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends State<AdminPostsScreen> {
  final ApiService _api = Get.find<ApiService>();
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  bool _reportedOnly = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/admin/posts', params: {
        if (_reportedOnly) 'reported': '1',
      });
      if (response['success']) {
        setState(() {
          _posts = List<Map<String, dynamic>>.from(response['data']['posts'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading posts: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _hidePost(int id) async {
    try {
      await _api.post('/admin/posts/$id/hide');
      Get.snackbar('Succès', 'Publication masquée.');
      _loadPosts();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
  }

  Future<void> _deletePost(int id) async {
    try {
      await _api.delete('/admin/posts/$id');
      Get.snackbar('Succès', 'Publication supprimée.');
      _loadPosts();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Modération des publications'),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          FilterChip(
            label: const Text('Signalées'),
            selected: _reportedOnly,
            onSelected: (v) {
              setState(() => _reportedOnly = v);
              _loadPosts();
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(child: Text('Aucune publication'))
              : ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    final user = post['user'] ?? {};
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(user['name'] ?? 'Utilisateur'),
                        subtitle: Text(
                          post['content'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'hide') _hidePost(post['id']);
                            if (value == 'delete') _deletePost(post['id']);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'hide', child: Text('Masquer')),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
