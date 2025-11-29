// lib/screens/main_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' hide Marker;

import '../providers/city_provider.dart';
import '../models/city_model.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  // Contrôleur pour la carte OpenStreetMap
  final MapController mapController = MapController();

  // Suivi de la ville précédemment affichée
  String? _previousCityId;

  // ===============================
  // 1. Initialisation de la ville
  // ===============================
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('DEBUG: didChangeDependencies called.');

    final cityProvider = Provider.of<CityProvider>(context, listen: false);
    final currentCity = cityProvider.currentCity;

    if (_previousCityId == null && currentCity != null) {
      _previousCityId = currentCity.id;
      print("DEBUG: Initial City ID set to $_previousCityId");
    }
  }

  // ===============================================
  // 2. Détection des changements pour bouger la map
  // ===============================================
 

  // =========================
  //    Weather animation
  // =========================
  String _getWeatherAssetPath(String condition) {
    final lower = condition.toLowerCase();

    if (lower.contains('pluie') || lower.contains('averse')) {
      return 'assets/rain.json';
    } else if (lower.contains('neige')) {
      return 'assets/snow.json';
    } else if (lower.contains('soleil') ||
        lower.contains('clair') ||
        lower.contains('clear')) {
      return 'assets/sun.json';
    } else if (lower.contains('vent') ||
        lower.contains('rafale') ||
        lower.contains('wind')) {
      return 'assets/wind.json';
    }
    return 'assets/wind.json';
  }

  // =============================
  // UI — Widgets flottants
  // =============================
  Widget _buildSearchBar(BuildContext context) {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          print("DEBUG: Search bar tapped");
          Navigator.of(context).pushNamed('/search_city');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.grey),
              SizedBox(width: 10),
              Text(
                'Chercher une autre ville...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherOverlay(BuildContext context, City city) {
    return Positioned(
      top: 140,
      left: 16,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.55,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              city.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              city.country,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${city.currentTemp.toStringAsFixed(0)}°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Lottie.asset(
                  _getWeatherAssetPath(city.weatherCondition),
                  width: 50,
                  height: 50,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              city.weatherCondition,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAppBar(BuildContext context) {
    return Positioned(
      bottom: 25,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:  [
            _PoiIcon(icon: Icons.favorite, label: 'Favoris'),
            _PoiIcon(icon: Icons.restaurant, label: 'Manger'),
            _PoiIcon(icon: Icons.park, label: 'Nature'),
            _PoiIcon(icon: Icons.museum, label: 'Culture'),
            _PoiIcon(icon: Icons.local_cafe, label: 'Cafés'),
          ],
        ),
      ),
    );
  }

  // POI Icon Widget
  static  Widget _PoiIcon({required IconData icon, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 28),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }

  // ================================
  // BUILD PRINCIPAL
  // ================================
  @override
  Widget build(BuildContext context) {
    print("DEBUG: MainPage build started");

    return Consumer<CityProvider>(
      builder: (context, cityProvider, child) {
      
        final City? city = cityProvider.currentCity;
      // Detect city change inside the Consumer
      if (city != null) {
        final String currentCityId = city.id;

        if (_previousCityId != currentCityId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            mapController.move(
              LatLng(city.latitude, city.longitude),
              12.0,
            );
          });
          _previousCityId = currentCityId;
        }
      }


        if (city == null) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  });

  return const Scaffold(
    body: Center(child: Text("Chargement de la ville...")),
  );
}


        final LatLng center = LatLng(city.latitude, city.longitude);

        final Marker cityMarker = Marker(
          width: 40,
          height: 40,
          point: center,
          child: const Icon(
            Icons.location_on,
            size: 40,
            color: Colors.red,
          ),
        );

        return Scaffold(
          body: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 12.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.example.explorez_votre_ville',
                        ),
                        MarkerLayer(markers: [cityMarker]),
                      ],
                    ),
                  );
                },
              ),

              _buildSearchBar(context),
              _buildWeatherOverlay(context, city),
              _buildBottomAppBar(context),
            ],
          ),
        );
      },
    );
  }
}

