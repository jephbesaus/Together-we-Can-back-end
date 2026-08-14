import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  List<Conversation> _all = [];
  List<Conversation> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/messages/conversations');
      if (response['success']) {
        setState(() {
          _all = (response['data']['conversations'] as List)
              .map((item) => Conversation.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading conversations: $e');
    }
    setState(() => _isLoading = false);
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _results = [];
      } else {
        _results = _all
            .where((c) => c.user.name.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rechercher des messages'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const AppLoadingView(message: 'Chargement des conversations...')
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Nom du membre...',
                      prefixIcon: const Icon(Icons.search),
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
                  child: _searchController.text.trim().isEmpty
                      ? Center(
                          child: Text(
                            'Tapez un nom pour rechercher une conversation.',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        )
                      : _results.isEmpty
                          ? Center(
                              child: Text(
                                'Aucune conversation trouvée.',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                return _buildTile(_results[index]);
                              },
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildTile(Conversation conversation) {
    return ListTile(
      onTap: () => Get.to(() => ChatScreen(conversation: conversation)),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: conversation.user.profilePhoto != null
            ? CachedNetworkImageProvider(
                MediaService.resolveUrl(conversation.user.profilePhoto!)!)
            : null,
        backgroundColor: Colors.grey[300],
        child: conversation.user.profilePhoto == null
            ? Text(
                conversation.user.name.isNotEmpty
                    ? conversation.user.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(
        conversation.user.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        conversation.lastMessage?.content ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}
