import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class NominatimService {
  static const String baseUrl = "https://nominatim.openstreetmap.org/";

  // Get coordinates from a city name
  static Future<LatLng?> getCoordinatesFromCity(String city) async {
    try {
      final url = Uri.parse("$baseUrl/search?format=json&q=$city");
      final response = await http.get(url, headers: {"User-Agent": "FlutterApp"});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'].toString());
          final lon = double.tryParse(data[0]['lon'].toString());
          if (lat != null && lon != null) return LatLng(lat, lon);
        }
      }
    } catch (e) {
      print("Nominatim error: $e");
    }
    return null;
  }

  // Reverse geocode to get city name
  static Future<String?> getCityNameFromCoordinates(double lat, double lon) async {
    try {
      final url = Uri.parse("$baseUrl/reverse?lat=$lat&lon=$lon&format=json");
      final response = await http.get(url, headers: {"User-Agent": "FlutterApp"});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['address'] != null) {
          return data['address']['city'] ??
              data['address']['town'] ??
              data['address']['village'] ??
              data['address']['state'];
        }
      }
    } catch (e) {
      print("Nominatim reverse error: $e");
    }
    return null;
  }

  // Get POIs by city and category
  static Future<List<LatLng>> getPOIs(String city, String category) async {
    List<LatLng> points = [];
    try {
      final url = Uri.parse("$baseUrl/search?format=json&city=$city&q=$category");
      final response = await http.get(url, headers: {"User-Agent": "FlutterApp"});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        for (var item in data) {
          final lat = double.tryParse(item['lat'].toString());
          final lon = double.tryParse(item['lon'].toString());
          if (lat != null && lon != null) points.add(LatLng(lat, lon));
        }
      }
    } catch (e) {
      print("Nominatim POI error: $e");
    }
    return points;
  }

  // Get POIs within visible map bounds
  static Future<List<LatLng>> getPOIsInBounds({
    required LatLng southWest,
    required LatLng northEast,
    required String category,
  }) async {
    try {
      // viewbox = left, top, right, bottom => west, north, east, south
      final url = Uri.parse(
          "$baseUrl/search?format=json&q=$category&bounded=1&viewbox=${southWest.longitude},${northEast.latitude},${northEast.longitude},${southWest.latitude}");
      final response = await http.get(url, headers: {"User-Agent": "ExplorezVotreVilleApp"});
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) {
          final lat = double.tryParse(item['lat'].toString()) ?? 0.0;
          final lon = double.tryParse(item['lon'].toString()) ?? 0.0;
          return LatLng(lat, lon);
        }).toList();
      }
    } catch (e) {
      print("Nominatim POI bounds error: $e");
    }
    return [];
  }
}
