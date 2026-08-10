import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/models/post.dart';
import '../../widgets/post_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _api = Get.find<ApiService>();
  final TextEditingController _searchController = TextEditingController();
  List<Post> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final response = await _api.get('/posts/search', params: {'q': query.trim()});
      if (response['success']) {
        setState(() {
          _results = (response['data']['posts'] as List)
              .map((item) => Post.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      print('Error searching posts: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Rechercher des publications...',
            border: InputBorder.none,
          ),
          onSubmitted: _search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(_searchController.text),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasSearched
              ? Center(
                  child: Text(
                    'Recherchez des publications par mot-clé',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : _results.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun résultat',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final post = _results[index];
                        return PostWidget(
                          post: post,
                          onLike: () {},
                          onComment: () {},
                          onShare: () {},
                          onReport: () {},
                        );
                      },
                    ),
    );
  }
}
