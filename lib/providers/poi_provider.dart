// lib/providers/poi_provider.dart

import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../services/places_service.dart';
import '../services/database_service.dart'; // ⚠️ Import de la base de données

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

  // C'est ici que tout se joue
  Future<void> searchPois(double lat, double lon, String categoryKey, {bool forceRefresh = false}) async {
    // Si on reclique sur la même catégorie, on désactive
   // ⚠️ CORRECTION : On ne vide la liste QUE si ce n'est PAS un rafraichissement forcé
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

      // ⚠️ LOGIQUE DE TRI : LOCAL (SQLite) vs DISTANT (API)
      if (categoryKey.toLowerCase() == 'favoris') {
        print("🔍 Recherche des favoris dans SQLite...");
        // On récupère les lieux stockés localement
        fetchedPois = await DatabaseService.instance.getAllPlaces();
        
        if (fetchedPois.isEmpty) {
          _errorMessage = "Aucun lieu favori enregistré pour le moment.";
        }
      } else {
        // Pour les autres catégories (Manger, Culture...), on appelle Google Places
        print("🌍 Recherche API Google pour : $categoryKey");
        fetchedPois = await _placesService.fetchNearbyPlaces(lat, lon, categoryKey);
        
        if (fetchedPois.isEmpty) {
          _errorMessage = "Aucun lieu trouvé pour '$categoryKey' autour de vous.";
        }
      }

      _currentPois = fetchedPois;
      print('✅ POI chargés : ${_currentPois.length} lieux.');

    } catch (e) {
      _errorMessage = 'Erreur lors de la récupération : ${e.toString()}';
      print('PoiProvider Error: $_errorMessage');
      _currentPois = [];
      _activeCategory = null; 
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}