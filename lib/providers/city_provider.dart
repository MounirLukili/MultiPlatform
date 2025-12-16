import 'package:flutter/material.dart';
import '../models/city_model.dart';
import '../services/geoloc_service.dart';
import '../services/weather_service.dart';
import '../services/database_service.dart'; 
import '../services/city_search_service.dart'; 

class CityProvider with ChangeNotifier {
  final GeolocService _geolocService = GeolocService();
  final WeatherService _weatherService = WeatherService();
  final CitySearchService _searchService = CitySearchService();

  City? _currentCity; 
  bool _isLoading = false;
  String? _errorMessage;
  List<City> _searchResults = [];
  bool _isSearching = false;
  City? get currentCity => _currentCity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<City> get searchResults => _searchResults;
  bool get isSearching => _isSearching;


  // Démarre le processus de géolocalisation et de récupération des données de la ville 
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

      await _fetchWeatherAndSave(city);

    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
      print('CityProvider Error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCity(City city) async {
    _isLoading = true;
    notifyListeners();
    await _fetchWeatherAndSave(city); 
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchWeatherAndSave(City city) async {
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

      // SAUVEGARDE AUTO DANS LA BDD
      await DatabaseService.instance.insertCity(_currentCity!);
      
    } catch (e) {
      _currentCity = city; 
      _errorMessage = 'Météo non disponible.';
      await DatabaseService.instance.insertCity(_currentCity!);
    }
  }

  

  

 
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