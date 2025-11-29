// lib/providers/city_provider.dart

import 'package:flutter/material.dart';
import '../models/city_model.dart';
import '../services/geoloc_service.dart';
import '../services/weather_service.dart';
import '../services/city_search_service.dart'; // ⚠️ NOUVELLE IMPORTATION

class CityProvider with ChangeNotifier {
  final GeolocService _geolocService = GeolocService();
  final WeatherService _weatherService = WeatherService();
  final CitySearchService _searchService = CitySearchService(); // ⚠️ NOUVEAU SERVICE

  City? _currentCity; // La ville actuellement affichée/explorée
  bool _isLoading = false;
  String? _errorMessage;
  
  // ⚠️ Nouvelles variables pour la recherche
  List<City> _searchResults = [];
  bool _isSearching = false;

  City? get currentCity => _currentCity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<City> get searchResults => _searchResults;
  bool get isSearching => _isSearching;


  // 1. Démarre le processus de géolocalisation et de récupération des données de la ville (inchangé)
  Future<void> findCurrentCityAndWeather(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _geolocService.checkAndRequestPermission();

      final position = await _geolocService.getCurrentPosition();
      final lat = position.latitude;
      final lon = position.longitude;

      final cityData = await _geolocService.reverseGeocode(lat, lon);

      City city = City.fromCoordinates(
        name: cityData['city'],
        country: cityData['country'],
        latitude: lat,
        longitude: lon,
      );

      await _fetchWeatherForCity(city);

    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
      print('CityProvider Error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Récupère la météo et met à jour la ville actuelle (inchangé)
  Future<void> _fetchWeatherForCity(City city) async {
    try {
      final weatherData = await _weatherService.fetchWeather(city.latitude, city.longitude);

      _currentCity = city.copyWithWeather(
        currentTemp: weatherData['currentTemp'],
        minTemp: weatherData['minTemp'],
        maxTemp: weatherData['maxTemp'],
        weatherCondition: weatherData['weatherCondition'],
        humidity: weatherData['humidity'],
        windSpeed: weatherData['windSpeed'],
      );
      // ⚠️ Important : Si la ville actuelle change, nous devons zoomer la carte
      // Pour l'instant, on laisse la logique de zoom sur la MainPage.
    } catch (e) {
      _currentCity = city; 
      _errorMessage = 'Météo non disponible: ${e.toString()}';
      print('Weather Fetch Error: $_errorMessage');
    }
  }

  // 3. Permet de définir une ville manuellement (utilisée après une recherche)
  // et de la définir comme ville courante.
  Future<void> setCity(City city) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Récupération de la météo pour la nouvelle ville (nécessaire pour avoir les détails météo)
    await _fetchWeatherForCity(city);

    _isLoading = false;
    // La météo est déjà mise à jour dans _currentCity, notifions l'UI
    notifyListeners();
  }

  // ⚠️ 4. Nouvelle méthode de recherche de ville (Fonctionnalité 1.3)
  Future<void> searchCity(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _searchService.searchCities(query);
      _searchResults = results;
      
      if (_searchResults.isEmpty) {
        _errorMessage = "Aucune ville trouvée pour '$query'.";
      }

    } catch (e) {
      _errorMessage = "Erreur de recherche: ${e.toString()}";
      _searchResults = [];
      print('City Search Error: $_errorMessage');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
}