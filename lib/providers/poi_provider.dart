// lib/providers/poi_provider.dart

import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../services/places_service.dart';
import '../services/database_service.dart';

class PoiProvider with ChangeNotifier {
  final PlacesService _placesService = PlacesService();

  List<Place> _currentPois = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _activeCategory; 

  List<Place> get currentPois => _currentPois;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get activeCategory => _activeCategory;

  void clearPois() {
    _currentPois = [];
    _activeCategory = null;
    notifyListeners();
  }

  // ⚠️ MODIFICATION : On ajoute le paramètre optionnel [cityName]
  Future<void> searchPois(double lat, double lon, String categoryKey, {bool forceRefresh = false, String? cityName}) async {
    
    if (!forceRefresh && _activeCategory == categoryKey && _currentPois.isNotEmpty) {
      clearPois();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _activeCategory = categoryKey;
    notifyListeners();

    try {
      List<Place> fetchedPois = [];

      // ⚠️ LOGIQUE DE FILTRE
      if (categoryKey.toLowerCase() == 'favoris') {
        print("🔍 Recherche des favoris...");
        if (cityName != null) {
          // Si on a un nom de ville, on ne charge que ceux-là !
          fetchedPois = await DatabaseService.instance.getPlacesForCity(cityName);
        } else {
          // Sinon on charge tout (sécurité)
          fetchedPois = await DatabaseService.instance.getAllPlaces();
        }
        
        if (fetchedPois.isEmpty) {
          _errorMessage = "Aucun favori trouvé à $cityName.";
        }
      } else {
        // Recherche API Google normale
        fetchedPois = await _placesService.fetchNearbyPlaces(lat, lon, categoryKey);
        
        if (fetchedPois.isEmpty) {
          _errorMessage = "Aucun lieu trouvé pour '$categoryKey'.";
        }
      }

      _currentPois = fetchedPois;

    } catch (e) {
      _errorMessage = 'Erreur : ${e.toString()}';
      _currentPois = [];
      _activeCategory = null; 
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}