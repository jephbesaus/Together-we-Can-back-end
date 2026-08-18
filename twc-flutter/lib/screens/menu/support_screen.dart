import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final ApiService _api = Get.find<ApiService>();

  String _email = 'Supporttogetherwecan@gmail.com';
  String _whatsapp = '+243 994435517';
  String _whatsappNumber = '243994435517';
  String _facebook = 'https://www.facebook.com/profile.php?id=61591784764691';
  String _whatsappGroup = 'https://chat.whatsapp.com/FNm8J0RpVqV8TQ0QcQu1nn';
  bool _isLoading = true;

  static const _faqs = [
    {
      'q': 'Comment recharger mon solde ?',
      'a': 'Va dans Portefeuille > Déposer, choisis ton opérateur mobile money (Orange, MTN, Vodacom, Airtel, Africell), entre le montant et ton numéro.',
    },
    {
      'q': 'Comment devenir vendeur sur la Marketplace ?',
      'a': 'Ouvre la Marketplace puis appuie sur le bouton "+" pour ajouter ton premier produit. Il sera visible après validation par un administrateur.',
    },
    {
      'q': 'Comment fonctionne le parrainage ?',
      'a': 'Partage ton code depuis l\'onglet Réseau. Quand quelqu\'un s\'inscrit avec ton code, tu gagnes 1 000 CDF.',
    },
    {
      'q': 'J\'ai oublié mon mot de passe, que faire ?',
      'a': 'Sur l\'écran de connexion, appuie sur "Mot de passe oublié ?" et suis les instructions envoyées par email.',
    },
    {
      'q': 'Comment obtenir le badge Premium ?',
      'a': 'Rends-toi dans le menu ☰ > Together Mode Premium et fais ta demande. Elle sera examinée par un administrateur.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSupportInfo();
  }

  Future<void> _loadSupportInfo() async {
    try {
      final response = await _api.get('/support');
      if (response['success']) {
        final support = response['data']['support'] ?? {};
        setState(() {
          _email = support['email'] ?? _email;
          _whatsapp = support['whatsapp'] ?? _whatsapp;
          _facebook = support['facebook'] ?? _facebook;
          _whatsappGroup = support['whatsapp_group'] ?? _whatsappGroup;
          // Extract number from whatsapp field
          _whatsappNumber = _whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
          if (_whatsappNumber.startsWith('243') == false) {
            _whatsappNumber = '243$_whatsappNumber';
          }
        });
      }
    } catch (e) {
      print('Error loading support info: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _contactEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _email,
      query: 'subject=Support Together We Can',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar('Erreur', 'Aucune application email disponible.');
    }
  }

  Future<void> _contactWhatsApp() async {
    final uri = Uri.parse('https://wa.me/$_whatsappNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Erreur', 'Impossible d\'ouvrir WhatsApp.');
    }
  }

  Future<void> _openFacebook() async {
    final uri = Uri.parse(_facebook);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Erreur', 'Impossible d\'ouvrir Facebook.');
    }
  }

  Future<void> _openWhatsAppGroup() async {
    final uri = Uri.parse(_whatsappGroup);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Erreur', 'Impossible d\'ouvrir le groupe WhatsApp.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Support & Aide'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Questions fréquentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._faqs.map((faq) => ExpansionTile(
                      title: Text(faq['q']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(faq['a']!, style: TextStyle(color: Colors.grey[600])),
                        ),
                      ],
                    )),
                const SizedBox(height: 24),
                const Text('Nous contacter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.email_outlined, color: AppConstants.primaryColor),
                    title: const Text('Envoyer un email'),
                    subtitle: Text(_email),
                    onTap: _contactEmail,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.chat_outlined, color: AppConstants.primaryColor),
                    title: const Text('WhatsApp'),
                    subtitle: Text(_whatsapp),
                    onTap: _contactWhatsApp,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.facebook, color: AppConstants.primaryColor),
                    title: const Text('Facebook'),
                    subtitle: const Text('Together We Can'),
                    onTap: _openFacebook,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.group_outlined, color: AppConstants.primaryColor),
                    title: const Text('Groupe WhatsApp'),
                    subtitle: const Text('Rejoindre la communauté'),
                    onTap: _openWhatsAppGroup,
                  ),
                ),
              ],
            ),
    );
  }
}
