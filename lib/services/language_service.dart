import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageCodeKey = 'language_code';
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Locale getLocale() {
    if (_prefs == null) {
      return const Locale('fr'); // Default to French
    }

    final String? languageCode = _prefs!.getString(_languageCodeKey);
    return Locale(languageCode ?? 'fr');
  }

  Future<void> setLocale(Locale locale) async {
    if (_prefs == null) {
      await initialize();
    }

    await _prefs!.setString(_languageCodeKey, locale.languageCode);
  }

  List<Locale> getSupportedLocales() {
    return const [
      Locale('fr'), // French
      Locale('en'), // English
    ];
  }

  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      default:
        return 'Unknown';
    }
  }
}
