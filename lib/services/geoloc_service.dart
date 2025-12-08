import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/foundation.dart';

class GeolocService {

  Future<LocationPermission> checkAndRequestPermission() async {
    bool serviceEnabled;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      serviceEnabled = true;
    }

    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied || permission == LocationPermission.unableToDetermine) {
      try {
        permission = await Geolocator.requestPermission();
      } catch (_) {
        return LocationPermission.whileInUse;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }
    
    return permission;
  }

  Future<Position> getCurrentPosition() async {
    try {
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        return lastPosition;
      }
    } catch (_) {}

    LocationAccuracy accuracy = LocationAccuracy.low;
    
    if (!kIsWeb && !Platform.isLinux) {
      accuracy = LocationAccuracy.high;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: const Duration(seconds: 15),
      );
      return position;
    } catch (e) {
      rethrow;
    }
  }

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
        final address = data['address'];
        final city = address['city'] ?? address['town'] ?? address['village'] ?? 'Inconnue';
        final country = address['country'] ?? 'N/A';
        return {'city': city, 'country': country, 'latitude': lat, 'longitude': lon};
      } else {
        return Future.error('Failed to reverse geocode.');
      }
    } catch (_) {
      return Future.error('Network error during reverse geocoding.');
    }
  }
}
