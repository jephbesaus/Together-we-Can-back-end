import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes.dart';
import '../../app/constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_service.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _auth = Get.find<AuthService>();
  bool _isLoading = false;
  String? _email;
  bool _isResetFlow = false;

  @override
  void initState() {
    super.initState();
    _email = Get.arguments?['email'] as String?;
    _isResetFlow = Get.arguments?['purpose'] == 'reset';
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      Get.snackbar('Erreur', 'Le code OTP doit faire 6 chiffres.');
      return;
    }

    // Pour le parcours "mot de passe oublié", le code sera vérifié directement
    // par /auth/reset-password : on passe simplement à l'écran suivant.
    if (_isResetFlow) {
      Get.toNamed(AppRoutes.resetPassword, arguments: {'email': _email, 'otp': otp});
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _auth.verifyOtp(_email!, otp);
      if (response['success']) {
        Get.offAllNamed(AppRoutes.discover);
        Get.snackbar('Succès', 'Compte vérifié !');
      } else {
        Get.snackbar(
          'Erreur',
          ApiService.extractErrorMessage(response['error'], fallback: 'Code OTP invalide.'),
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau. Veuillez réessayer.');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);

    try {
      final response = _isResetFlow
          ? await _auth.forgotPassword(_email!)
          : await _auth.resendOtp(_email!);
      if (response['success']) {
        Get.snackbar('Succès', 'Un nouveau code a été envoyé.');
      } else {
        Get.snackbar(
          'Erreur',
          ApiService.extractErrorMessage(response['error'], fallback: 'Échec de l\'envoi.'),
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau. Veuillez réessayer.');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.security_outlined,
                size: 80,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(height: 16),
              const Text(
                '🔐 Vérification',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Un code à 6 chiffres a été envoyé à',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                _email ?? 'email@example.com',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              // OTP Input
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Code OTP',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          '✅ Vérifier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Resend
              TextButton(
                onPressed: _isLoading ? null : _resendOtp,
                child: const Text(
                  '🔄 Renvoyer le code',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
