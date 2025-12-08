import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Pour encoder la ville en JSON
import '../models/city_model.dart';

class PreferencesService {
  static const String _keyTheme = 'is_dark_mode';
  static const String _keyDefaultCity = 'default_city_json';

  // --- THÈME ---
  
  Future<void> saveThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTheme, isDark);
  }

  Future<bool?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTheme);
  }

  // --- VILLE PAR DÉFAUT ---

  Future<void> saveDefaultCity(City city) async {
    final prefs = await SharedPreferences.getInstance();
    // On convertit l'objet City en String JSON pour le stocker
    String cityJson = json.encode(city.toMap());
    await prefs.setString(_keyDefaultCity, cityJson);
  }

  Future<City?> getDefaultCity() async {
    final prefs = await SharedPreferences.getInstance();
    String? cityJson = prefs.getString(_keyDefaultCity);
    
    if (cityJson == null) return null;

    try {
      Map<String, dynamic> map = json.decode(cityJson);
      return City.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearDefaultCity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDefaultCity);
  }
}