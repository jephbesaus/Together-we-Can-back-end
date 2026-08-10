import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Together We Can';
  static const String appVersion = '1.0.0';

  // Backend déployé sur Render
  static const String apiBaseUrl = 'https://together-we-can-back-end-pqel.onrender.com/api';
  static const String wsBaseUrl = 'ws://localhost:8080';

  static const Color primaryColor = Color(0xFF00A86B);
  static const Color primaryDark = Color(0xFF008C5A);
  static const Color secondaryColor = Color(0xFF111111);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color darkBackground = Color(0xFF0B0B0B);
  static const Color darkSurface = Color(0xFF1E1E1E);

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String currentUserIdKey = 'current_user_id';
  static const String themeKey = 'theme_mode';

  static const int defaultLimit = 20;
  static const int maxLimit = 50;
}
