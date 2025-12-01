// lib/screens/main_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' hide Marker;

import '../providers/city_provider.dart';
import '../providers/poi_provider.dart';
import '../services/database_service.dart';
import '../models/city_model.dart';
import '../models/place_model.dart';
import 'place_detail_screen.dart';
import 'add_place_dialog.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  final MapController mapController = MapController();
  String? _previousCityId;
  
  // Clé pour forcer le rafraichissement de la liste des favoris
  int _refreshKey = 0; 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cityProvider = Provider.of<CityProvider>(context, listen: false);
    final currentCity = cityProvider.currentCity;

    if (_previousCityId == null && currentCity != null) {
      _previousCityId = currentCity.id;
    }
  }

  // Méthode pour rafraichir la liste des favoris en bas
  void _refreshFavorites() {
    setState(() {
      _refreshKey++;
    });
  }

  // --- MÉTÉO ---
  String _getWeatherAssetPath(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('pluie') || lower.contains('averse')) return 'assets/rain.json';
    if (lower.contains('neige')) return 'assets/snow.json';
    if (lower.contains('soleil') || lower.contains('clair') || lower.contains('clear')) return 'assets/sun.json';
    return 'assets/wind.json';
  }

  // --- LOGIQUE D'AJOUT DE LIEU (Fonctionnalité 1.4) ---
  void _openAddPlaceDialog(LatLng location) {
    // ⚠️ CRUCIAL : On récupère la ville actuelle pour l'associer au nouveau lieu
    final currentCity = Provider.of<CityProvider>(context, listen: false).currentCity;
    final String cityName = currentCity?.name ?? 'Ville Inconnue';

    showDialog(
      context: context,
      builder: (ctx) => AddPlaceDialog(
        location: location, 
        cityName: cityName, // ⚠️ On passe le paramètre requis
      ),
    ).then((added) {
      if (added == true) {
        _refreshFavorites(); // On recharge la liste du bas après ajout
      }
    });
  }

  // --- 1. BARRE DE RECHERCHE ---
  Widget _buildSearchBar(BuildContext context) {
    return Positioned(
      top: 50, left: 16, right: 16,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed('/search_city'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.grey),
              SizedBox(width: 10),
              Text('Chercher une autre ville...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. MÉTÉO ---
  Widget _buildWeatherOverlay(BuildContext context, City city) {
    return Positioned(
      top: 130, left: 16,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.50,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(city.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(city.country, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${city.currentTemp.toStringAsFixed(0)}°', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w300)),
                Lottie.asset(
                  _getWeatherAssetPath(city.weatherCondition), 
                  width: 40, height: 40,
                  errorBuilder: (_,__,___) => const Icon(Icons.error, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. MENU CATÉGORIES (PETITS RONDS) ---
  Widget _buildCategoryBar(BuildContext context, City city) {
    return Positioned(
      top: 260, // Sous la météo
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMiniPoiIcon(context, city, Icons.favorite, 'favoris', Colors.red),
            const SizedBox(width: 10),
            _buildMiniPoiIcon(context, city, Icons.restaurant, 'manger', Colors.orange),
            const SizedBox(width: 10),
            _buildMiniPoiIcon(context, city, Icons.park, 'nature', Colors.green),
            const SizedBox(width: 10),
            _buildMiniPoiIcon(context, city, Icons.museum, 'culture', Colors.purple),
            const SizedBox(width: 10),
            _buildMiniPoiIcon(context, city, Icons.local_cafe, 'cafés', Colors.brown),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPoiIcon(BuildContext context, City city, IconData icon, String key, Color color) {
    // Utilise Consumer pour l'état actif, ou Provider.of si c'est juste le callback
    // Ici on veut savoir s'il est actif pour la couleur
    return Consumer<PoiProvider>(
      builder: (context, poiProvider, child) {
        final isSelected = poiProvider.activeCategory == key;
        
        return GestureDetector(
          onTap: () => poiProvider.searchPois(city.latitude, city.longitude, key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.grey.shade200,
              shape: BoxShape.circle,
              boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)] : [],
            ),
            child: Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.grey),
          ),
        );
      },
    );
  }

  // --- 4. LISTE DES FAVORIS LOCAUX (EN BAS) ---
  Widget _buildLocalFavoritesList(BuildContext context, City city) {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      height: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Text(
              "Vos lieux à ${city.name}",
              style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, 
                color: Colors.black87, 
                shadows: [Shadow(color: Colors.white, blurRadius: 10)]
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Place>>(
              key: ValueKey(_refreshKey), // Force le reload
              future: DatabaseService.instance.getPlacesForCity(city.name), // ⚠️ Filtre par ville
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final places = snapshot.data ?? [];

                if (places.isEmpty) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(15)),
                      child: const Text("Aucun lieu favori ici.", style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: places.length,
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return _AnimatedPlaceCard(
                      place: place,
                      onTap: () async {
                        // Navigation
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
                        );
                        _refreshFavorites();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================================
  // BUILD PRINCIPAL
  // ================================
  @override
  Widget build(BuildContext context) {
    return Consumer<CityProvider>(
      builder: (context, cityProvider, child) {
        final City? city = cityProvider.currentCity;

        // Gestion du zoom/changement de ville
        if (city != null) {
          final String currentCityId = city.id;
          if (_previousCityId != currentCityId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              mapController.move(LatLng(city.latitude, city.longitude), 13.0);
              Provider.of<PoiProvider>(context, listen: false).clearPois();
            });
            _previousCityId = currentCityId;
          }
        }

        if (city == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final LatLng center = LatLng(city.latitude, city.longitude);

        return Scaffold(
          // FAB Ajout (positionné plus haut pour éviter la liste du bas)
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 160.0), 
            child: FloatingActionButton(
              mini: true,
              onPressed: () => _openAddPlaceDialog(mapController.camera.center),
              backgroundColor: Colors.amber,
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ),

          body: Stack(
            children: [
              // 1. CARTE
              Consumer<PoiProvider>(
                builder: (context, poiProvider, child) {
                  // Construction des marqueurs
                  final List<Marker> markers = poiProvider.currentPois.map((place) {
                    return Marker(
                      width: 40, height: 40, 
                      point: LatLng(place.latitude, place.longitude),
                      child: GestureDetector(
                        onTap: () async {
                           // ⚠️ IMPORTANCE CAPITALE : Injection de la ville
                           // C'est ça qui permet de retrouver le favori dans la liste du bas plus tard
                           final placeWithCity = place.copyWith(cityName: city.name);

                           await Navigator.of(context).push(
                             MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: placeWithCity))
                           );
                           _refreshFavorites();
                        },
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                    );
                  }).toList();

                  return FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: center, initialZoom: 13.0,
                      // Gestion du Long Press
                      onLongPress: (_, point) => _openAddPlaceDialog(point),
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                    ),
                    children: [
                      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.explorez_votre_ville'),
                      MarkerLayer(markers: markers),
                    ],
                  );
                },
              ),

              // 2. WIDGETS UI
              _buildSearchBar(context),
              _buildWeatherOverlay(context, city),
              _buildCategoryBar(context, city),
              _buildLocalFavoritesList(context, city),
              
              // 3. Gestion Erreur POI
              Consumer<PoiProvider>(
                builder: (context, poiProvider, child) {
                   if (poiProvider.errorMessage != null) {
                     WidgetsBinding.instance.addPostFrameCallback((_) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text(poiProvider.errorMessage!), backgroundColor: Colors.red),
                       );
                     });
                   }
                   return const SizedBox.shrink();
                },
              )
            ],
          ),
        );
      },
    );
  }
}

// --- WIDGET CARD ANIMÉE (Interne) ---
class _AnimatedPlaceCard extends StatefulWidget {
  final Place place;
  final VoidCallback onTap;

  const _AnimatedPlaceCard({required this.place, required this.onTap});

  @override
  State<_AnimatedPlaceCard> createState() => _AnimatedPlaceCardState();
}

class _AnimatedPlaceCardState extends State<_AnimatedPlaceCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12, bottom: 5, top: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: widget.place.imageUrl.isNotEmpty
                      ? Image.network(widget.place.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, size: 30, color: Colors.grey)))
                      : Container(color: Colors.grey.shade200, child: Icon(Icons.image, size: 30, color: Colors.grey.shade400)),
                ),
              ),
              // Texte
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.place.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(widget.place.category, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}