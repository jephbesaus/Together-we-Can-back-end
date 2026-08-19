import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/media_service.dart';
import '../../core/models/conversation.dart';
import 'chat_screen.dart';
import '../../widgets/app_loader.dart';

class SearchMessagesScreen extends StatefulWidget {
  const SearchMessagesScreen({super.key});

  @override
  State<SearchMessagesScreen> createState() => _SearchMessagesScreenState();
}

class _SearchMessagesScreenState extends State<SearchMessagesScreen> {
  final ApiService _api = Get.find<ApiService>();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String q) async {
    if (q.trim().length < 2) {
      setState(() { _users = []; _hasSearched = false; });
      return;
    }

    setState(() { _isLoading = true; _hasSearched = true; });

    try {
      final response = await _api.get('/messages/search-users', params: {'q': q.trim()});
      if (response['success']) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response['data']['users'] ?? []);
        });
      }
    } catch (e) {
      print('Error searching users: $e');
    }

    setState(() => _isLoading = false);
  }

  void _openChat(Map<String, dynamic> user) {
    final conversation = Conversation.fromJson({
      'id': 'new',
      'other_user': user,
      'last_message': null,
      'last_message_at': null,
      'unread_count': 0,
      'is_archived': false,
      'is_blocked': false,
      'created_at': DateTime.now().toIso8601String(),
    });
    Get.to(() => ChatScreen(conversation: conversation));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Nouvelle conversation'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (v) {
                if (v.trim().length >= 2) _searchUsers(v);
                else setState(() { _users = []; _hasSearched = false; });
              },
              decoration: InputDecoration(
                hintText: 'Rechercher un membre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() { _users = []; _hasSearched = false; });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Tapez un nom pour trouver un membre.',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : _users.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun membre trouvé.',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return _buildUserTile(user);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final profilePhoto = user['profile_photo'];
    final name = user['name'] ?? '';
    final isPremium = user['is_premium'] ?? false;

    return ListTile(
      onTap: () => _openChat(user),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[300],
        backgroundImage: profilePhoto != null
            ? CachedNetworkImageProvider(MediaService.resolveUrl(profilePhoto)!)
            : null,
        child: profilePhoto == null
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              )
            : null,
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chat_bubble_outline, size: 20, color: AppConstants.primaryColor),
    );
  }
}
