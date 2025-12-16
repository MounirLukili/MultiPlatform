import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class GeolocService {

  
  // Permissions → Jamais utilisées sur Desktop
  
  Future<LocationPermission> checkAndRequestPermission() async {
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      return LocationPermission.whileInUse; 
    }

    // --- MOBILE ---
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Les services de localisation sont désactivés.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied || 
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Les permissions de localisation sont refusées.');
    }

    return permission;
  }

  // 2. Obtenir position → Desktop = IP, Mobile = GPS
  Future<Position> getCurrentPosition() async {
    // DESKTOP → On ne tente jamais Geolocator
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      return await _getPositionFromIP();
    }

    // --- MOBILE---
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 3),
      );
    } catch (e) {
      print("⚠️ GPS échec : fallback IP. Erreur : $e");
      return await _getPositionFromIP();
    }
  }

  
  // 3. Fallback par IP (Desktop)
 
  Future<Position> _getPositionFromIP() async {
    try {
      final response = await http
          .get(Uri.parse('http://ip-api.com/json'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return Position(
          latitude: data['lat'] ?? 48.8566,
          longitude: data['lon'] ?? 2.3522,
          timestamp: DateTime.now(),
          accuracy: 5000,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    } catch (e) {
      print("⚠️ Erreur récuperation IP : $e");
    }

    // En dernier recours → Paris par défaut
    return Position(
      latitude: 48.8566,
      longitude: 2.3522,
      timestamp: DateTime.now(),
      accuracy: 5000,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  // 4. Reverse Geocoding (adresse → ville/pays)
  Future<Map<String, dynamic>> reverseGeocode(double lat, double lon) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'ExplorezVotreVilleFlutterApp/1.0'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] ?? {};
        final city = address['city'] ??
            address['town'] ??
            address['village'] ??
            'Position Inconnue';
        final country = address['country'] ?? '';

        return {
          'city': city,
          'country': country,
          'latitude': lat,
          'longitude': lon
        };
      }
    } catch (e) {
      print("⚠️ Reverse geocode erreur : $e");
    }

    return {
      'city': 'Ma Position',
      'country': '',
      'latitude': lat,
      'longitude': lon
    };
  }
}
