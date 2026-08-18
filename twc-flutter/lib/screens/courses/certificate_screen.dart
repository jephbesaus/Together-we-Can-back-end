import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/constants.dart';

class CertificateScreen extends StatelessWidget {
  final String? certificateUrl;
  final String courseTitle;
  final String userName;
  final String completedAt;

  const CertificateScreen({
    super.key,
    this.certificateUrl,
    required this.courseTitle,
    required this.userName,
    required this.completedAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Certificat'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, size: 80, color: AppConstants.primaryColor),
              const SizedBox(height: 24),
              const Text(
                'Felicitations !',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Vous avez termine la formation',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                courseTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text('Nom : $userName', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text('Date : $completedAt', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 32),
              if (certificateUrl != null && certificateUrl!.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(certificateUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      Get.snackbar('Erreur', 'Impossible d\'ouvrir le certificat.');
                    }
                  },
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text('Telecharger le certificat', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else
                Text(
                  'Le certificat sera disponible apres validation.',
                  style: TextStyle(color: Colors.grey[500]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
