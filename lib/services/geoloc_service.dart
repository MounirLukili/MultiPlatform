// lib/services/geoloc_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ⚠️ API Key Note: Pour la vraie géocodage inverse, il est courant d'utiliser
// Google Maps Geocoding API ou Nominatim. Nous utiliserons Nominatim pour cet exemple
// car il ne nécessite pas de clé API payante pour une utilisation basique.

class GeolocService {

  // Méthode pour demander l'autorisation de géolocalisation
  Future<LocationPermission> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Les services de localisation ne sont pas activés.
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Les permissions sont refusées.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Les permissions sont refusées de manière permanente.
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }
    return permission;
  }

  // Méthode pour obtenir la position GPS actuelle
  Future<Position> getCurrentPosition() async {
    // ⚠️ Ajout d'un timeout sur la récupération de la position pour éviter le blocage
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10)
    );
  }

  // Méthode pour faire de la géocodage inverse (coordonnées -> ville/pays)
  // Utilisation de l'API Nominatim (OpenStreetMap)
  Future<Map<String, dynamic>> reverseGeocode(double lat, double lon) async {
    final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1';
    
    try {
      // ⚠️ Ajout du User-Agent et d'un Timeout sur la requête HTTP
      final response = await http.get(
        Uri.parse(url),
        headers: {
          // Ceci est OBLIGATOIRE pour Nominatim lorsqu'on appelle depuis une application
          'User-Agent': 'ExplorezVotreVilleFlutterApp/1.0', 
        },
      ).timeout(const Duration(seconds: 8)); // Timeout de 8 secondes
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        final city = address['city'] ?? address['town'] ?? address['village'] ?? 'Inconnue';
        final country = address['country'] ?? 'N/A';
        
        // Vérification supplémentaire si le géocodage n'a rien trouvé de pertinent
        if (city == 'Inconnue') {
          print('Géocodage inverse: Ville non trouvée, renvoie Inconnue.');
          return Future.error('Ville non trouvée. Coordonnées trop éloignées d\'une zone urbaine connue.');
        }

        return {
          'city': city,
          'country': country,
          'latitude': lat,
          'longitude': lon,
        };
      } else {
        print('Erreur lors de la géocodage inverse: ${response.statusCode} - ${response.body}');
        return Future.error('Failed to reverse geocode location. (HTTP Code: ${response.statusCode})');
      }
    } catch (e) {
      // Gère les erreurs réseau, les timeouts, et les erreurs de parsing JSON
      print('Erreur réseau lors de la géocodage inverse: $e');
      return Future.error('Network error or Timeout during reverse geocoding: ${e.toString()}');
    }
  }
}