import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final ApiService _api = Get.find<ApiService>();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({String? q}) async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/admin/users', params: {
        if (q != null && q.isNotEmpty) 'q': q,
      });
      if (response['success']) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response['data']['users'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading users: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleBlock(Map<String, dynamic> user) async {
    final id = user['id'];
    final isBlocked = user['is_blocked'] == true;
    try {
      final response = await _api.post(isBlocked ? '/admin/users/$id/unblock' : '/admin/users/$id/block');
      if (response['success']) {
        Get.snackbar('Succès', isBlocked ? 'Utilisateur débloqué.' : 'Utilisateur bloqué.');
        _loadUsers(q: _searchController.text);
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Supprimer cet utilisateur ?'),
        content: Text('${user['name']} sera définitivement supprimé. Cette action est irréversible.'),
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
        final response = await _api.delete('/admin/users/${user['id']}');
        if (response['success']) {
          Get.snackbar('Succès', 'Utilisateur supprimé.');
          _loadUsers(q: _searchController.text);
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
        title: const Text('Gestion des utilisateurs'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher (nom, email, téléphone)...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (q) => _loadUsers(q: q),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('Aucun utilisateur trouvé'))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final isBlocked = user['is_blocked'] == true;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user['profile_photo_url'] != null
                                  ? CachedNetworkImageProvider(user['profile_photo_url'])
                                  : null,
                              backgroundColor: Colors.grey[300],
                              child: user['profile_photo_url'] == null
                                  ? Text((user['name'] ?? '?')[0].toUpperCase())
                                  : null,
                            ),
                            title: Text(user['name'] ?? ''),
                            subtitle: Text(
                              '${user['email'] ?? ''}${isBlocked ? ' • Bloqué' : ''}',
                              style: TextStyle(color: isBlocked ? Colors.red : null),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'toggle') _toggleBlock(user);
                                if (value == 'delete') _deleteUser(user);
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Text(isBlocked ? 'Débloquer' : 'Bloquer'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
