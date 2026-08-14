import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/constants.dart';

/// Surveille la connexion internet et affiche une modale centrée façon
/// Facebook ("Oups ! Pas de connexion internet") dès que le réseau disparaît.
class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();

  bool _isOnline = true;
  bool _isDialogVisible = false;

  Future<ConnectivityService> init() async {
    _connectivity.onConnectivityChanged.listen(_onChanged);
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = _hasInternet(results);
    } catch (_) {
      _isOnline = true;
    }
    return this;
  }

  bool get isOnline => _isOnline;

  bool _hasInternet(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return !results.every((r) =>
        r == ConnectivityResult.none);
  }

  void _onChanged(List<ConnectivityResult> results) {
    final online = _hasInternet(results);
    if (online == _isOnline) return;
    _isOnline = online;

    if (online) {
      _hideOfflineDialog();
    } else {
      _showOfflineDialog();
    }
  }

  void _showOfflineDialog() {
    if (_isDialogVisible) return;
    _isDialogVisible = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isDialogOpen! || !_isDialogVisible) {
        Get.dialog(
          const OfflineDialog(),
          barrierDismissible: false,
          barrierColor: Colors.black54,
          useSafeArea: false,
        );
      }
    });
  }

  void _hideOfflineDialog() {
    if (!_isDialogVisible) return;
    _isDialogVisible = false;
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }
}

class OfflineDialog extends StatelessWidget {
  const OfflineDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Oups ! Pas de connexion internet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez votre connexion Wi-Fi ou mobile et réessayez.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Réessayer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
