import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends GetxController {
  static const String localeKey = 'app_locale';

  final Rx<Locale> locale = const Locale('fr', 'FR').obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(localeKey);
    if (saved == 'en') {
      locale.value = const Locale('en', 'US');
    } else {
      locale.value = const Locale('fr', 'FR');
    }
    Get.updateLocale(locale.value);
  }

  Future<void> setLocale(String languageCode) async {
    locale.value = languageCode == 'en'
        ? const Locale('en', 'US')
        : const Locale('fr', 'FR');
    Get.updateLocale(locale.value);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(localeKey, languageCode);
  }
}
