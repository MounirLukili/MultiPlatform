// lib/services/places_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Pour kIsWeb
import '../models/place_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlacesService {
  static final String _apiKey = dotenv.env['GOOGLE_PLACES_KEY'] ?? '';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
  static const String _photoUrl = 'https://maps.googleapis.com/maps/api/place/photo';
  static const String _detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json';



    static const Map<String, String> categoryMap = {
      'favoris': 'favorite', 
      'manger': 'restaurant',
      'cafés': 'cafe',
      'nature': 'park',
      'culture': 'museum',
      'shopping': 'shopping_mall', 
      'hôtels': 'lodging',         
      'santé': 'pharmacy',         
      'banque': 'bank',            
      'essence': 'gas_station',    
    };
  // 1. Fonction pour construire l'URL de l'image
  String _buildPhotoUrl(String photoReference) {
    String url = '$_photoUrl?maxwidth=400&photo_reference=$photoReference&key=$_apiKey';
    
    if (kIsWeb) {
      return 'https://cors-anywhere.herokuapp.com/$url';
    }
    return url;
  }

  Future<List<Place>> fetchNearbyPlaces(double lat, double lon, String categoryKey) async {
    final String placeType = categoryMap[categoryKey.toLowerCase()] ?? '';
    
    if (placeType.isEmpty || placeType == 'favorite') return [];
    
    String url = '$_baseUrl?location=$lat,$lon&radius=5000&type=$placeType&key=$_apiKey';
    if (kIsWeb) url = 'https://cors-anywhere.herokuapp.com/$url';
    
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        
        return results.map((item) {
          final double itemLat = item['geometry']['location']['lat'] ?? 0.0;
          final double itemLon = item['geometry']['location']['lng'] ?? 0.0;
          
          final dynamic rawRating = item['rating'];
          final double rating = rawRating is int ? rawRating.toDouble() : rawRating is double ? rawRating : 0.0;
          
          String finalImageUrl = '';
          if (item['photos'] != null && (item['photos'] as List).isNotEmpty) {
            final String photoRef = item['photos'][0]['photo_reference'];
            finalImageUrl = _buildPhotoUrl(photoRef);
          } else {
            finalImageUrl = item['icon'] ?? ''; // Utilisation de l'icône par défaut
          }

          return Place(
            cityName: '', 
            title: item['name'] ?? 'Lieu Inconnu',
            description: item['vicinity'] ?? item['name'] ?? '',
            category: placeType, 
            latitude: itemLat,
            longitude: itemLon,
            imageUrl: finalImageUrl, // On utilise notre vraie URL photo ici
            rating: rating, 
            noteCount: item['user_ratings_total'] ?? 0,
            placeId: item['place_id'] ?? '', // On stocke l'ID pour plus tard
          );
        }).toList();
      } else {
        return Future.error('Échec HTTP: ${response.statusCode}');
      }
    } catch (e) {
      return Future.error('Erreur réseau : $e');
    }
  }

  
  Future<Map<String, dynamic>> fetchPlaceDetails(String placeId) async {
    String url = '$_detailsUrl?place_id=$placeId&fields=formatted_phone_number,website,opening_hours&key=$_apiKey';
    
    if (kIsWeb) url = 'https://cors-anywhere.herokuapp.com/$url';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'] ?? {};
      }
    } catch (e) {
      print("Erreur détails: $e");
    }
    return {};
  }

  Future<Place?> searchPlaceByText(String query, double lat, double lon) async {
    // On utilise l'endpoint 'textsearch'
    String url = 'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&location=$lat,$lon&radius=10000&key=$_apiKey';
    
    if (kIsWeb) url = 'https://cors-anywhere.herokuapp.com/$url';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        if (results.isNotEmpty) {
          final item = results.first; // On prend le premier résultat (le plus pertinent)
          
          final double itemLat = item['geometry']['location']['lat'];
          final double itemLon = item['geometry']['location']['lng'];
          
          // Récupération photo
          String finalImageUrl = '';
          if (item['photos'] != null && (item['photos'] as List).isNotEmpty) {
            finalImageUrl = _buildPhotoUrl(item['photos'][0]['photo_reference']);
          } else {
            finalImageUrl = item['icon'] ?? '';
          }

          // Tentative de deviner la catégorie (Google -> Notre App)
          String detectedCategory = 'Autre';
          final List<dynamic> types = item['types'] ?? [];
          
          if (types.contains('museum')) {
            detectedCategory = 'Musée';
          } else if (types.contains('park')) detectedCategory = 'Parc';
          else if (types.contains('stadium')) detectedCategory = 'Stade';
          else if (types.contains('restaurant') || types.contains('food')) detectedCategory = 'Restaurant';
          else if (types.contains('cafe')) detectedCategory = 'Café';
          else if (types.contains('movie_theater')) detectedCategory = 'Cinéma';

          return Place(
            placeId: item['place_id'],
            cityName: '', // Sera rempli par le contexte
            title: item['name'],
            description: item['formatted_address'] ?? '',
            category: detectedCategory,
            latitude: itemLat,
            longitude: itemLon,
            imageUrl: finalImageUrl,
            rating: (item['rating'] as num?)?.toDouble() ?? 0.0,
            noteCount: item['user_ratings_total'] ?? 0,
          );
        }
      }
    } catch (e) {
      print("Erreur recherche textuelle: $e");
    }
    return null; // si rien trouvé
  }

}