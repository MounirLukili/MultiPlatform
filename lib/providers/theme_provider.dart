// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class ThemeProvider with ChangeNotifier {
  final PreferencesService _prefs = PreferencesService();
  
  // MODIFICATION ICI : On force le mode CLAIR par défaut
  ThemeMode _themeMode = ThemeMode.light; 

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = await _prefs.getThemeMode();
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      // Si aucune préférence n'est sauvegardée, on reste sur Clair
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _prefs.saveThemeMode(isDark);
  }
}