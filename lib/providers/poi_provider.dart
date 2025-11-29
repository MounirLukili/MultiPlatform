// lib/providers/poi_provider.dart

import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../services/places_service.dart';

class PoiProvider with ChangeNotifier {
  final PlacesService _placesService = PlacesService();

  List<Place> _currentPois = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _activeCategory; // Catégorie actuellement sélectionnée (ex: 'manger')

  List<Place> get currentPois => _currentPois;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get activeCategory => _activeCategory;

  // Réinitialise les POI (pour changer de ville ou de catégorie)
  void clearPois() {
    _currentPois = [];
    _activeCategory = null;
    notifyListeners();
  }

  // Recherche de POI par catégorie et les affiche sur la carte
  Future<void> searchPois(double lat, double lon, String categoryKey) async {
    // Si on reclique sur la même catégorie, on la désélectionne et efface les POI
    if (_activeCategory == categoryKey && _currentPois.isNotEmpty) {
      _currentPois = [];
      _activeCategory = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _activeCategory = categoryKey;
    notifyListeners();

    try {
      final fetchedPois = await _placesService.fetchNearbyPlaces(lat, lon, categoryKey);
      _currentPois = fetchedPois;
      print('DEBUG: Found ${_currentPois.length} places for category $categoryKey.');
      
      if (_currentPois.isEmpty) {
        _errorMessage = "Aucun lieu trouvé pour '$categoryKey' dans un rayon de 5km.";
      }
    } catch (e) {
      _errorMessage = 'Erreur de recherche POI: ${e.toString()}';
      print('PoiProvider Error: $_errorMessage');
      _currentPois = [];
      _activeCategory = null; // Désactive la catégorie en cas d'erreur
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}