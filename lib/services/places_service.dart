// lib/services/places_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/place_model.dart';

class PlacesService {
  // ⚠️ REMPLACER PAR VOTRE CLÉ API GOOGLE PLACES
  static const String _apiKey = 'VOTRE_CLE_API_GOOGLE_PLACES_ICI'; 
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  // Mappage des icônes de l'application vers les types Google Places (en anglais)
  static const Map<String, String> categoryMap = {
    'manger': 'restaurant',
    'nature': 'park',
    'culture': 'museum',
    'cafés': 'cafe',
    'favoris': 'favorite', 
  };

  Future<List<Place>> fetchNearbyPlaces(double lat, double lon, String categoryKey) async {
    final String placeType = categoryMap[categoryKey.toLowerCase()] ?? '';
    
    if (placeType.isEmpty || placeType == 'favorite') {
       // Si c'est 'Favoris' ou une catégorie non mappée
       return Future.value([]); 
    }
    
    // Requête Nearby Search (rayon de 5000 mètres = 5 km)
    final url = '$_baseUrl?location=$lat,$lon&radius=5000&type=$placeType&key=$_apiKey';
    
    if (_apiKey == 'VOTRE_CLE_API_GOOGLE_PLACES_ICI') {
      throw Exception("Veuillez insérer votre clé API Google Places.");
    }
    
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        
        return results.map((item) {
          final double itemLat = item['geometry']['location']['lat'] ?? 0.0;
          final double itemLon = item['geometry']['location']['lng'] ?? 0.0;
          
          // ⚠️ CORRECTION: Récupération sécurisée du rating et conversion en double
          final dynamic rawRating = item['rating'];
          final double rating = rawRating is int 
                                ? rawRating.toDouble() 
                                : rawRating is double ? rawRating : 0.0;
          
          return Place(
            cityName: '', 
            title: item['name'] ?? 'Lieu Inconnu',
            description: item['vicinity'] ?? item['name'] ?? '',
            category: placeType, 
            latitude: itemLat,
            longitude: itemLon,
            imageUrl: item['icon'] ?? '', 
            // Utilise la valeur sécurisée que nous venons de calculer
            rating: rating, 
            noteCount: item['user_ratings_total'] ?? 0,
          );
        }).toList();

      } else {
        print('Google Places Error: ${response.statusCode} - ${response.body}');
        return Future.error('Échec de la recherche Google Places. Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Network Error: $e');
        return Future.error('Erreur réseau lors de la récupération des lieux.');}
  }
}