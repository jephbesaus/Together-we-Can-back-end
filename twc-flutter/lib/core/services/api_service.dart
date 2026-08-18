import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/constants.dart';

class ApiService {
  late Dio _dio;
  String? _token;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await logout();
        }
        return handler.next(error);
      },
    ));

    _initToken();
  }

  Future<void> _initToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
    return _token;
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  Future<void> setCurrentUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.currentUserIdKey, userId);
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.currentUserIdKey);
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.currentUserIdKey);
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.get(path, queryParameters: params);
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> patch(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> multipart(String path, FormData data) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>?> uploadFile(String path, File file, String fieldName, {String method = 'POST'}) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.request(
        path,
        data: formData,
        options: Options(method: method),
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Si le backend a répondu avec un JSON d'erreur (401, 422, 404...),
  /// on le retourne tel quel pour que l'UI affiche le vrai message.
  /// Sinon (pas de connexion, timeout...), on retourne une erreur générique.
  Map<String, dynamic> _handleError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data.containsKey('success')) {
      return data;
    }
    return {
      'success': false,
      'error': 'Erreur réseau. Vérifiez votre connexion et réessayez.',
    };
  }

  /// Laravel peut renvoyer 'error' comme une simple String OU comme un objet
  /// de validation { champ: [messages...] }. Ce helper retourne toujours
  /// une String affichable, sûre à passer à Get.snackbar / Text.
  static String extractErrorMessage(dynamic error, {String fallback = 'Une erreur est survenue.'}) {
    if (error == null) return fallback;
    if (error is String) return error;
    if (error is Map) {
      final messages = <String>[];
      error.forEach((key, value) {
        if (value is List) {
          messages.addAll(value.map((v) => v.toString()));
        } else {
          messages.add(value.toString());
        }
      });
      return messages.isNotEmpty ? messages.first : fallback;
    }
    return error.toString();
  }
}
