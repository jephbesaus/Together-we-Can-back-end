import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/models/user.dart';
import '../../core/models/conversation.dart';
import '../messages/chat_screen.dart';
import '../../widgets/verified_badge.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ApiService _api = Get.find<ApiService>();
  User? _user;
  bool _isFollowing = false;
  int _postsCount = 0;
  bool _isLoading = true;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);

    try {
      final response = await _api.get('/user/${widget.userId}');
      if (response['success']) {
        setState(() {
          _user = User.fromJson(response['data']['user']);
          _isFollowing = response['data']['is_following'] ?? false;
          _postsCount = response['data']['posts_count'] ?? 0;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _toggleFollow() async {
    setState(() => _isFollowLoading = true);

    try {
      final response = await _api.post('/users/${widget.userId}/follow');
      if (response['success']) {
        setState(() {
          _isFollowing = response['data']['following'] ?? !_isFollowing;
        });
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de suivre cet utilisateur.');
    }

    setState(() => _isFollowLoading = false);
  }

  void _openChat() {
    if (_user == null) return;
    // On construit une conversation "virtuelle" : ChatScreen se charge de
    // récupérer/créer la vraie conversation côté backend au chargement.
    final conversation = Conversation(
      id: '0',
      user: _user!,
      unreadCount: 0,
      isArchived: false,
      isBlocked: false,
      createdAt: DateTime.now(),
    );
    Get.to(() => ChatScreen(conversation: conversation));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: Text('Utilisateur introuvable')),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(_user!.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _user!.profilePhoto != null
                  ? CachedNetworkImageProvider(_user!.profilePhoto!)
                  : null,
              backgroundColor: Colors.grey[300],
              child: _user!.profilePhoto == null
                  ? Text(
                      _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _user!.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if (_user!.isPremium) ...[
                  const SizedBox(width: 6),
                  const VerifiedBadge(size: 20),
                ],
              ],
            ),
            if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _user!.bio!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat(_postsCount.toString(), 'Publications'),
                _stat(_user!.followersCount.toString(), 'Abonnés'),
                _stat(_user!.followingCount.toString(), 'Abonnements'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isFollowLoading ? null : _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isFollowing ? Colors.grey[300] : AppConstants.primaryColor,
                      foregroundColor: _isFollowing ? Colors.black87 : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(_isFollowing ? 'Abonné' : 'S\'abonner'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _openChat,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Contacter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}
