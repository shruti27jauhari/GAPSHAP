import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeModeNotifier() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode');
    if (themeModeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeModeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode newThemeMode) async {
    if (newThemeMode == _themeMode) return;

    _themeMode = newThemeMode;
    final prefs = await SharedPreferences.getInstance();
    String themeModeString;
    if (newThemeMode == ThemeMode.light) {
      themeModeString = 'light';
    } else if (newThemeMode == ThemeMode.dark) {
      themeModeString = 'dark';
    } else {
      themeModeString = 'system';
    }
    await prefs.setString('themeMode', themeModeString);
    notifyListeners();
  }
}
