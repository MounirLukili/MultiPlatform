// lib/services/weather_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  // ⚠️ Remplacer par votre clé API OpenWeatherMap
  static const String _apiKey = '69943523b8432650e299f19a33b5d3cb';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Map<String, dynamic>> fetchWeather(double lat, double lon) async {
    if (_apiKey == 'YOUR_OPENWEATHER_API_KEY') {
       throw Exception("Veuillez remplacer 'YOUR_OPENWEATHER_API_KEY' par votre clé OpenWeatherMap.");
    }
    // Appel à l'API OpenWeatherMap en utilisant les unités métriques (Celsius) et en français
    final url = '$_baseUrl?lat=$lat&lon=$lon&units=metric&lang=fr&appid=$_apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Mappage des données OpenWeatherMap vers une structure simple
        final weatherData = {
          'currentTemp': data['main']['temp'].toDouble(),
          'minTemp': data['main']['temp_min'].toDouble(),
          'maxTemp': data['main']['temp_max'].toDouble(),
          'weatherCondition': data['weather'][0]['description'] as String,
          'humidity': data['main']['humidity'] as int,
          // Conversion de la vitesse du vent de m/s à km/h (pour une meilleure lisibilité)
          'windSpeed': (data['wind']['speed'] * 3.6).toDouble(), 
        };
        return weatherData;

      } else {
        print('Erreur API Météo: ${response.statusCode}');
        return Future.error('Erreur lors de la récupération de la météo.');
      }
    } catch (e) {
      print('Erreur réseau Météo: $e');
      return Future.error('Erreur de connexion lors de la récupération de la météo.');
    }
  }
}