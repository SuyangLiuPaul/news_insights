import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide settings: locale (en / zh — matches exactly what the
/// yswords-data feed provides; not attempting Traditional Chinese for
/// v1) and theme mode. Deliberately small — this app has far fewer
/// settings than a full Bible-reading app.
class AppSettings extends ChangeNotifier {
  static const _localeKey = 'newsInsights.locale';
  static const _themeModeKey = 'newsInsights.themeMode';

  String _locale = 'en';
  ThemeMode _themeMode = ThemeMode.system;

  String get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString(_localeKey) ?? _deviceDefaultLocale();
    final modeStr = prefs.getString(_themeModeKey);
    _themeMode = switch (modeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  String _deviceDefaultLocale() {
    final code = WidgetsBinding
        .instance.platformDispatcher.locale.languageCode
        .toLowerCase();
    return code == 'zh' ? 'zh' : 'en';
  }

  Future<void> setLocale(String locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale);
  }

  void toggleLocale() => setLocale(_locale == 'en' ? 'zh' : 'en');

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }
}
