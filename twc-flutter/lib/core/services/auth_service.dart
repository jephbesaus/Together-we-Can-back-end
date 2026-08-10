import 'package:get/get.dart';
import 'api_service.dart';

class AuthService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> get currentUserId => _api.getCurrentUserId();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    if (response['success'] && response['data']['token'] != null) {
      await _api.setToken(response['data']['token']);
      final userId = response['data']['user']?['id'];
      if (userId != null) {
        await _api.setCurrentUserId(userId.toString());
      }
    }
    return response;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _api.post('/auth/register', data: data);
    if (response['success'] && response['data']['token'] != null) {
      await _api.setToken(response['data']['token']);
      final userId = response['data']['user']?['id'];
      if (userId != null) {
        await _api.setCurrentUserId(userId.toString());
      }
    }
    return response;
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    return await _api.post('/auth/verify-otp', data: {
      'email': email,
      'otp': otp,
    });
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await _api.post('/auth/forgot-password', data: {
      'email': email,
    });
  }

  Future<Map<String, dynamic>> resendOtp(String email) async {
    return await _api.post('/auth/resend-otp', data: {
      'email': email,
    });
  }

  Future<Map<String, dynamic>> resetPassword(Map<String, dynamic> data) async {
    return await _api.post('/auth/reset-password', data: data);
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (e) {
      // On nettoie quand même la session locale, même si l'appel réseau échoue
    }
    await _api.logout();
  }
}
