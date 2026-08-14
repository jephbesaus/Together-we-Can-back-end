import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/media_service.dart';
import '../../core/models/post.dart';
import '../profile/user_profile_screen.dart';
import '../../widgets/app_loader.dart';

class CommentsScreen extends StatefulWidget {
  final Post post;

  const CommentsScreen({super.key, required this.post});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final ApiService _api = Get.find<ApiService>();
  final TextEditingController _commentController = TextEditingController();

  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/posts/${widget.post.id}/comments');
      if (response['success']) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(
            response['data']['comments'] ?? [],
          );
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final response = await _api.post(
        '/posts/${widget.post.id}/comments',
        data: {'content': content},
      );

      if (response['success']) {
        _commentController.clear();
        if (mounted) FocusScope.of(context).unfocus();
        Get.snackbar('Commenté', 'Votre commentaire a été publié.');
        _loadComments();
      } else {
        Get.snackbar(
          'Erreur',
          ApiService.extractErrorMessage(response['error'], fallback: 'Échec de l\'envoi.'),
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }

    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Commentaires (${widget.post.commentsCount})'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const AppLoadingView(message: 'Chargement des commentaires...')
                : _comments.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun commentaire. Soyez le premier !',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          return _buildComment(_comments[index]);
                        },
                      ),
          ),
          // Input bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(),
                      decoration: InputDecoration(
                        hintText: 'Écrire un commentaire...',
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendComment,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: AppConstants.primaryColor,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment(Map<String, dynamic> comment) {
    final user = comment['user'] as Map<String, dynamic>? ?? {};
    final name = user['name'] ?? 'Utilisateur';
    final profilePhoto = user['profile_photo_url'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Get.to(() => UserProfileScreen(userId: user['id'].toString())),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: profilePhoto != null
                  ? CachedNetworkImageProvider(MediaService.resolveUrl(profilePhoto)!)
                  : null,
              backgroundColor: Colors.grey[300],
              child: profilePhoto == null
                  ? Text(
                      name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comment['content'] ?? '',
                    style: const TextStyle(fontSize: 14, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment['created_at'] != null
                        ? timeago.format(DateTime.parse(comment['created_at']).toLocal())
                        : '',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
