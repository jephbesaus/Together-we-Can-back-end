import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/constants.dart';
import '../screens/discover/discover_screen.dart';
import '../screens/messages/messages_screen.dart';
import '../screens/network/network_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/discover/create_post_screen.dart';
import '../screens/discover/create_story_screen.dart';
import '../core/controllers/notification_controller.dart';
import '../core/services/api_service.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;
  int _unreadMessages = 0;
  int _unreadNotifications = 0;

  final List<Widget> _screens = [
    const DiscoverScreen(),
    const MessagesScreen(),
    Container(),
    const NetworkScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  void _loadBadges() async {
    try {
      final api = Get.find<ApiService>();
      final messages = await api.get('/messages/unread-count');
      final notifs = await api.get('/notifications/unread-count');
      if (mounted) {
        setState(() {
          _unreadMessages = messages['data']?['unread_count'] ?? 0;
          _unreadNotifications = notifs['data']?['unread_count'] ?? 0;
        });
      }
    } catch (e) {}
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _showCreateMenu();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) _loadBadges();
  }

  void _showCreateMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Créer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.dynamic_feed, color: AppConstants.primaryColor),
              title: const Text('Publication'),
              subtitle: const Text('Texte, photos ou vidéo'),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => const CreatePostScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_motion, color: AppConstants.primaryColor),
              title: const Text('Story'),
              subtitle: const Text('Visible 24h, modèle uniforme'),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => const CreateStoryScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields, color: AppConstants.primaryColor),
              title: const Text('Texte'),
              subtitle: const Text('Publication texte uniquement'),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => const CreatePostScreen());
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Découvrir',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _unreadMessages > 0,
              label: Text('$_unreadMessages', style: const TextStyle(fontSize: 10, color: Colors.white)),
              backgroundColor: Colors.red,
              child: const Icon(Icons.message_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: _unreadMessages > 0,
              label: Text('$_unreadMessages', style: const TextStyle(fontSize: 10, color: Colors.white)),
              backgroundColor: Colors.red,
              child: const Icon(Icons.message),
            ),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Réseau',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
