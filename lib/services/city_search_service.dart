// lib/services/city_search_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/city_model.dart';

class CitySearchService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  // Recherche des villes par nom 
  Future<List<City>> searchCities(String query) async {
    if (query.isEmpty) {
      return [];
    }

    //Encoder la requête pour gérer les espaces et caractères spéciaux
    final encodedQuery = Uri.encodeComponent(query);
    
    // param : format JSON, limite de 5 résultats.
    final url = '$_baseUrl?q=$encodedQuery&format=json&extratags=1&limit=5&addressdetails=1';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        // User-Agent plus détaillé pour une meilleure acceptation par Nominatim
        headers: {
          'User-Agent': 'ExplorezVotreVilleFlutterApp/1.0 (Contact: projet.m1.info@univ-orleans.fr)', 
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        
        return results.map((item) {
          final double lat = double.tryParse(item['lat'] ?? '0.0') ?? 0.0;
          final double lon = double.tryParse(item['lon'] ?? '0.0') ?? 0.0;
          
          final String displayName = item['display_name'] ?? 'Ville inconnue';
          
          // xtraire le pays
          final List<String> parts = displayName.split(',').map((s) => s.trim()).toList();
          final String country = parts.length > 1 ? parts.last : 'N/A';
          
          // obtenir le nom de la ville à partir de l'adresse 
          final address = item['address'] ?? {};
          // Utilise locality, city, town, ou le premier segment de display_name comme fallback
          final city = address['locality'] ?? address['city'] ?? address['town'] ?? address['village'] ?? parts.first;
          
          // Si le nom de la ville est toujours l'ID numérique, utilise display_name
          final finalCityName = (city.toString().contains(RegExp(r'\d')) && !city.toString().contains(RegExp(r'[a-zA-Z]'))) 
                               ? parts.first 
                               : city;


          // Création d'une instance de City (sans la météo pour l'instant)
          return City.fromCoordinates(
            name: finalCityName,
            country: country,
            latitude: lat,
            longitude: lon,
          );
        }).toList();

      } else {
        print('Échec de la recherche de ville. Code: ${response.statusCode}');
        return Future.error('Échec de la recherche de ville. Code: ${response.statusCode}');
      }
    } on Exception catch (e) {
      print('Erreur réseau lors de la recherche de ville: ${e.toString()}');
      return Future.error('Erreur réseau lors de la recherche de ville: ${e.toString()}');
    }
  }
}