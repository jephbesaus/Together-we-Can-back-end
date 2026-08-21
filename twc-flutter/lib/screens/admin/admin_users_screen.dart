import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/formatters.dart';

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
      } else {
        final msg = ApiService.extractErrorMessage(
          response['error'],
          fallback: 'Erreur de chargement.',
        );
        Get.snackbar('Erreur serveur', msg, duration: const Duration(seconds: 10));
      }
    } catch (e) {
      Get.snackbar('Erreur réseau', e.toString(), duration: const Duration(seconds: 10));
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
        content: Text('${user['name']} sera définitivement supprimé.'),
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

  Future<void> _updateBalance(Map<String, dynamic> user) async {
    final balanceController = TextEditingController(
      text: double.tryParse('${user['boost_balance'] ?? 0}')?.toStringAsFixed(0) ?? '0',
    );

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Solde de ${user['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Solde actuel : ${Formatters.cdf(user['boost_balance'])}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau solde (CDF)',
                hintText: 'Ex: 3000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Le solde sera remplacé par ce montant exact.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final amount = double.tryParse(balanceController.text.trim());
    if (amount == null || amount < 0) {
      Get.snackbar('Erreur', 'Montant invalide.');
      return;
    }

    try {
      final response = await _api.post('/admin/users/${user['id']}/balance', data: {
        'amount': amount,
      });
      if (response['success']) {
        Get.snackbar('Succès', response['data']?['message'] ?? 'Solde mis à jour.');
        _loadUsers(q: _searchController.text);
      } else {
        Get.snackbar(
          'Erreur',
          ApiService.extractErrorMessage(response['error'], fallback: 'Échec de la mise à jour.'),
        );
      }
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
        title: const Text('Gestion des utilisateurs'),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadUsers(q: _searchController.text),
          ),
        ],
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.cardColor,
              ),
              onSubmitted: (q) => _loadUsers(q: q),
            ),
          ),
          // Stats bar
          if (_users.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _buildStat('${_users.length}', 'Total', Colors.blue),
                  const SizedBox(width: 12),
                  _buildStat('${_users.where((u) => u['is_blocked'] == true).length}', 'Bloqués', Colors.red),
                  const SizedBox(width: 12),
                  _buildStat('${_users.where((u) => u['role'] == 'admin').length}', 'Admins', Colors.amber),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('Aucun utilisateur trouvé'))
                    : RefreshIndicator(
                        onRefresh: () => _loadUsers(q: _searchController.text),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _users.length,
                          itemBuilder: (context, index) => _buildUserCard(_users[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isBlocked = user['is_blocked'] == true;
    final isAdmin = user['role'] == 'admin';
    final isPremium = user['is_premium'] == true;
    final balance = double.tryParse('${user['boost_balance'] ?? 0}') ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: user['profile_photo_url'] != null
                      ? CachedNetworkImageProvider(user['profile_photo_url'])
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: user['profile_photo_url'] == null
                      ? Text(
                          (user['name'] ?? '?')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null,
                ),
                if (isBlocked)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.block, size: 12, color: Colors.white),
                    ),
                  ),
                if (isAdmin)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                      child: const Icon(Icons.star, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Premium', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user['email'] ?? '',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.cdf(balance),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      if (user['phone'] != null) ...[
                        Icon(Icons.phone, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          '${user['phone']}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'balance') _updateBalance(user);
                if (value == 'toggle') _toggleBlock(user);
                if (value == 'delete') _deleteUser(user);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'balance',
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, size: 18, color: AppConstants.primaryColor),
                      const SizedBox(width: 8),
                      Text('Définir le solde', style: TextStyle(color: AppConstants.primaryColor)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(isBlocked ? Icons.lock_open : Icons.lock, size: 18, color: isBlocked ? Colors.green : Colors.orange),
                      const SizedBox(width: 8),
                      Text(isBlocked ? 'Débloquer' : 'Bloquer'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
