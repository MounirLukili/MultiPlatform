// lib/services/geoloc_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/foundation.dart';

class GeolocService {

  // --- 1. GESTION DES PERMISSIONS (AVEC DEBUG) ---
  Future<LocationPermission> checkAndRequestPermission() async {
    print("🔍 [DEBUG] Vérification du service de localisation...");
    
    bool serviceEnabled;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print("🔍 [DEBUG] Service activé : $serviceEnabled");
    } catch (e) {
      print("⚠️ [DEBUG] Impossible de vérifier le statut du service : $e");
      serviceEnabled = true; // On assume que oui sur Linux pour ne pas bloquer
    }

    if (!serviceEnabled) {
      print("❌ [DEBUG] Le service est désactivé au niveau OS.");
      return Future.error('Location services are disabled.');
    }

    print("🔍 [DEBUG] Vérification des permissions de l'app...");
    LocationPermission permission = await Geolocator.checkPermission();
    print("🔍 [DEBUG] Statut permission actuel : $permission");

    if (permission == LocationPermission.denied || permission == LocationPermission.unableToDetermine) {
      print("⚠️ [DEBUG] Permission manquante. Tentative de demande...");
      try {
        // Sur Linux, cette ligne renvoie souvent une erreur "Unimplemented", c'est normal.
        // L'autorisation réelle se fait au moment de getCurrentPosition via l'Agent.
        permission = await Geolocator.requestPermission();
        print("🔍 [DEBUG] Résultat de la demande : $permission");
      } catch (e) {
        print("🐧 [DEBUG] requestPermission() non supporté sur cette plateforme (Linux probable). On continue.");
        // On retourne une valeur positive pour laisser passer la suite
        return LocationPermission.whileInUse;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("❌ [DEBUG] Permission refusée définitivement.");
      return Future.error('Location permissions are permanently denied.');
    }
    
    return permission;
  }

  // --- 2. RÉCUPÉRATION DE LA POSITION (LE COEUR DU PROBLÈME) ---
  Future<Position> getCurrentPosition() async {
    print("----------------------------------------------------------------");
    print("🚀 [DEBUG] Démarrage de getCurrentPosition()...");

    // 1. Test du Cache
    try {
      print("🕵️ [DEBUG] Interrogation du cache (LastKnownPosition)...");
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        print("✅ [DEBUG] CACHE TROUVÉ !");
        print("   -> Lat: ${lastPosition.latitude}, Lon: ${lastPosition.longitude}");
        print("   -> Date: ${lastPosition.timestamp}");
        return lastPosition;
      } else {
        print("⚠️ [DEBUG] Cache vide.");
      }
    } catch (e) {
      print("⚠️ [DEBUG] Erreur lecture cache : $e");
    }

    // 2. Définition de la précision
    // Essayons 'low' pour voir si Linux arrive à nous trouver via l'IP
    LocationAccuracy accuracy = LocationAccuracy.low; 
    
    if (!kIsWeb && Platform.isLinux) {
      print("🐧 [DEBUG] Mode Linux détecté.");
      print("ℹ️ [DEBUG] Utilisation de LocationAccuracy.low (Précision Ville/IP) pour maximiser les chances.");
    } else {
      accuracy = LocationAccuracy.high;
    }

    // 3. Appel bloquant au système
    print("📡 [DEBUG] Appel à Geolocator.getCurrentPosition(accuracy: $accuracy)...");
    print("⏳ [DEBUG] En attente de la réponse de GeoClue (Linux)...");

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: const Duration(seconds: 15) // Timeout 15s
      );
      
      print("----------------------------------------------------------------");
      print("✅ [DEBUG] 📍 POSITION REÇUE AVEC SUCCÈS !");
      print("   -> Latitude  : ${position.latitude}");
      print("   -> Longitude : ${position.longitude}");
      print("   -> Précision : ${position.accuracy} mètres");
      print("   -> Altitude  : ${position.altitude}");
      print("   -> Vitesse   : ${position.speed}");
      print("----------------------------------------------------------------");
      
      return position;

    } catch (e) {
      print("----------------------------------------------------------------");
      print("❌ [DEBUG] ÉCHEC DE LA LOCALISATION");
      print("   -> Erreur exacte : $e");
      print("----------------------------------------------------------------");
      rethrow;
    }
  }

  // --- 3. REVERSE GEOCODING (Inchangé) ---
  Future<Map<String, dynamic>> reverseGeocode(double lat, double lon) async {
    final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1';
    print("🌍 [DEBUG] Reverse Geocoding pour $lat, $lon...");
    
    try {
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'ExplorezVotreVilleFlutterApp/1.0'})
          .timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("✅ [DEBUG] Ville trouvée : ${data['address']['city'] ?? data['address']['town']}");
        final address = data['address'];
        final city = address['city'] ?? address['town'] ?? address['village'] ?? 'Inconnue';
        final country = address['country'] ?? 'N/A';
        return {'city': city, 'country': country, 'latitude': lat, 'longitude': lon};
      } else {
        print("❌ [DEBUG] Erreur API Nominatim : ${response.statusCode}");
        return Future.error('Failed to reverse geocode.');
      }
    } catch (e) {
      print("❌ [DEBUG] Erreur Réseau Geocoding : $e");
      return Future.error('Network error during reverse geocoding.');
    }
  }
}