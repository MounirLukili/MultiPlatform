// lib/screens/main_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'dart:async'; // ⚠️ Nécessaire pour le Timer (Debounce)

import '../providers/city_provider.dart';
import '../providers/poi_provider.dart';
import '../providers/theme_provider.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../models/city_model.dart';
import '../models/place_model.dart';
import 'place_detail_screen.dart';
import 'add_place_dialog.dart';
import 'city_drawer.dart';
import 'poi_carousel.dart'; 
import '../screens/ai_assistant_screen.dart'; 

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  final MapController mapController = MapController();
  // Clé globale pour le Drawer (Menu)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  String? _previousCityId;
  int _refreshKey = 0; 
  bool _showCarousel = false;
  
  // Timer pour éviter de spammer l'API quand on bouge la carte
  Timer? _moveDebounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cityProvider = Provider.of<CityProvider>(context, listen: false);
    final currentCity = cityProvider.currentCity;

    if (_previousCityId == null && currentCity != null) {
      _previousCityId = currentCity.id;
    }
  }

  @override
  void dispose() {
    _moveDebounce?.cancel(); // Nettoyage du timer
    super.dispose();
  }

  void _refreshFavorites() {
    setState(() {
      _refreshKey++;
    });
  }

  // --- LOGIQUE ACTUALISATION CARTE (Debounce) ---
 // ⚠️ VERSION CORRIGÉE POUR VOTRE CONFIGURATION ACTUELLE
  void _onMapPositionChanged(dynamic position, bool hasGesture) {
    if (!hasGesture) return;

    final poiProvider = Provider.of<PoiProvider>(context, listen: false);
    
    if (poiProvider.activeCategory == null || poiProvider.activeCategory == 'favoris') return;

    if (_moveDebounce?.isActive ?? false) _moveDebounce!.cancel();

    _moveDebounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        // Si vous êtes en v6
        final center = position.center; 
        // Si vous êtes en v5, utilisez : final center = position.center;

        print("🌍 Actualisation pour : ${center.latitude}, ${center.longitude}");
        
        poiProvider.searchPois(
          center.latitude, 
          center.longitude, 
          poiProvider.activeCategory!,
          forceRefresh: true // ⚠️ AJOUTEZ CECI !
        );
      }
    });
  }

  String _getWeatherAssetPath(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('pluie') || lower.contains('averse')) return 'assets/rain.json';
    if (lower.contains('neige')) return 'assets/snow.json';
    if (lower.contains('soleil') || lower.contains('clair') || lower.contains('clear')) return 'assets/sun.json';
    return 'assets/wind.json';
  }

  // --- AJOUT LIEU ---
  void _openAddPlaceDialog(LatLng location) {
    final currentCity = Provider.of<CityProvider>(context, listen: false).currentCity;
    final String cityName = currentCity?.name ?? 'Ville Inconnue';

    showDialog(
      context: context,
      builder: (ctx) => AddPlaceDialog(
        location: location, 
        cityName: cityName,
      ),
    ).then((added) {
      if (added == true) {
        _refreshFavorites();
      }
    });
  }

  // --- NAVIGATION ANIMÉE ---
  Future<void> _navigateToDetail(Place place) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PlaceDetailScreen(place: place),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutQuart;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
    _refreshFavorites();
  }

  // --- PARAMÈTRES ---
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final isDark = themeProvider.themeMode == ThemeMode.dark;

        return AlertDialog(
          title: const Text("Paramètres"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text("Mode Sombre"),
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                value: isDark,
                onChanged: (val) {
                  themeProvider.toggleTheme(val);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text("Oublier ma ville par défaut"),
                onTap: () async {
                  await PreferencesService().clearDefaultCity();
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Ville par défaut effacée.")),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Fermer")),
          ],
        );
      },
    );
  }

  // --- WIDGETS UI ---

  Widget _buildSearchBar(BuildContext context) {
    return Positioned(
      top: 50, left: 16, right: 16,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]),
              child: const Icon(Icons.menu, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/search_city'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]),
                child: const Row(children: [Icon(Icons.search, color: Colors.grey), SizedBox(width: 10), Text('Chercher une ville...', style: TextStyle(color: Colors.grey))]),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showSettingsDialog,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]),
              child: const Icon(Icons.settings, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherOverlay(BuildContext context, City city) {
    return Positioned(
      top: 130, left: 16,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.50,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(city.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(city.country, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${city.currentTemp.toStringAsFixed(0)}°', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w300)),
            Lottie.asset(_getWeatherAssetPath(city.weatherCondition), width: 40, height: 40, errorBuilder: (_,__,___) => const Icon(Icons.error, color: Colors.white))
          ])
        ]),
      ),
    );
  }

  Widget _buildCategoryBar(BuildContext context, City city) {
    return Positioned(
      top: 260, left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(30), boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 5)]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _buildMiniPoiIcon(context, city, Icons.favorite, 'favoris', Colors.red),
          const SizedBox(width: 10), _buildMiniPoiIcon(context, city, Icons.restaurant, 'manger', Colors.orange),
          const SizedBox(width: 10), _buildMiniPoiIcon(context, city, Icons.park, 'nature', Colors.green),
          const SizedBox(width: 10), _buildMiniPoiIcon(context, city, Icons.museum, 'culture', Colors.purple),
          const SizedBox(width: 10), _buildMiniPoiIcon(context, city, Icons.local_cafe, 'cafés', Colors.brown),
        ]),
      ),
    );
  }

  Widget _buildMiniPoiIcon(BuildContext context, City city, IconData icon, String key, Color color) {
    return Consumer<PoiProvider>(builder: (context, poiProvider, child) {
      final isSelected = poiProvider.activeCategory == key;
      return GestureDetector(
        onTap: () {
          poiProvider.searchPois(city.latitude, city.longitude, key);
          setState(() { _showCarousel = !isSelected; });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: isSelected ? color : Colors.grey.shade200, shape: BoxShape.circle, boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)] : []),
          child: Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.grey),
        ),
      );
    });
  }

  Widget _buildLocalFavoritesList(BuildContext context, City city) {
    if (_showCarousel) return const SizedBox.shrink();
    return Positioned(
      bottom: 20, left: 0, right: 0, height: 160,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), child: Text("Vos lieux à ${city.name}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, shadows: [Shadow(color: Colors.white, blurRadius: 10)]))),
        Expanded(child: FutureBuilder<List<Place>>(
          key: ValueKey(_refreshKey),
          future: DatabaseService.instance.getPlacesForCity(city.name),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final places = snapshot.data ?? [];
            if (places.isEmpty) {
              return Center(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(15)), child: const Text("Aucun lieu favori ici.", style: TextStyle(color: Colors.grey))));
            }
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: places.length,
              itemBuilder: (context, index) {
                final place = places[index];
                return _AnimatedPlaceCard(place: place, onTap: () => _navigateToDetail(place));
              },
            );
          },
        )),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CityProvider>(
      builder: (context, cityProvider, child) {
        final City? city = cityProvider.currentCity;

        if (city != null) {
          final String currentCityId = city.id;
          if (_previousCityId != currentCityId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              mapController.move(LatLng(city.latitude, city.longitude), 13.0);
              Provider.of<PoiProvider>(context, listen: false).clearPois();
              setState(() => _showCarousel = false);
            });
            _previousCityId = currentCityId;
          }
        }

        if (city == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final LatLng center = LatLng(city.latitude, city.longitude);

        return Scaffold(
          key: _scaffoldKey, // ⚠️ Indispensable pour le drawer
          drawer: const CityDrawer(),
          
          floatingActionButton: Padding(
  padding: const EdgeInsets.only(bottom: 160.0), 
  child: Column(
    mainAxisSize: MainAxisSize.min, // Important pour ne pas prendre toute la hauteur
    children: [
      // BOUTON IA (NOUVEAU)
      // ... dans le build de MainPage ...

      // BOUTON IA
      FloatingActionButton(
        heroTag: "btn_ai", 
        mini: true,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
        
        // ⚠️ C'est ICI la modification
        onPressed: () async {
          // 1. On attend que l'utilisateur revienne de l'écran IA
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AiAssistantScreen())
          );

          // 2. Si l'écran IA a renvoyé un lieu (objet Place)
          if (result != null && result is Place) {
            
            // A. On déplace la carte sur ce lieu
            mapController.move(
              LatLng(result.latitude, result.longitude), 
              15.0
            );

            // B. On ouvre directement la fiche détail (Transition fluide)
            _navigateToDetail(result);
          }
        },
      ),
      
      const SizedBox(height: 10), // Espace entre les boutons

      // BOUTON AJOUT (EXISTANT)
      FloatingActionButton(
        heroTag: "btn_add", // Tag unique
        mini: true,
        onPressed: () => _openAddPlaceDialog(mapController.camera.center),
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    ],
  ),
),

          body: Stack(
            children: [
              Consumer<PoiProvider>(
                builder: (context, poiProvider, child) {
                  final List<Marker> markers = poiProvider.currentPois.map((place) {
                    return Marker(
                      width: 40, height: 40, 
                      point: LatLng(place.latitude, place.longitude),
                      child: GestureDetector(
                        onTap: () {
                           final placeWithCity = place.copyWith(cityName: city.name);
                           _navigateToDetail(placeWithCity);
                        },
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                    );
                  }).toList();

                  return FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: center, initialZoom: 13.0,
                      onLongPress: (_, point) => _openAddPlaceDialog(point),
                      onPositionChanged: _onMapPositionChanged, // ⚠️ Auto-refresh
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                    ),
                    children: [
                      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.explorez_votre_ville'),
                      MarkerLayer(markers: markers),
                    ],
                  );
                },
              ),

              _buildSearchBar(context),
              _buildWeatherOverlay(context, city),
              _buildCategoryBar(context, city),
              _buildLocalFavoritesList(context, city),

              Consumer<PoiProvider>(
                builder: (context, poiProvider, child) {
                  if (_showCarousel && poiProvider.currentPois.isNotEmpty) {
                    return Positioned(
                      bottom: 20, left: 0, right: 0,
                      child: PoiCarousel(
                        places: poiProvider.currentPois,
                        onPlaceChanged: (place) {
                          mapController.move(LatLng(place.latitude, place.longitude), 15.0);
                        },
                        onPlaceTap: (place) {
                          final placeWithCity = place.copyWith(cityName: city.name);
                          _navigateToDetail(placeWithCity);
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              Consumer<PoiProvider>(
                builder: (context, poiProvider, child) {
                   if (poiProvider.errorMessage != null) {
                     WidgetsBinding.instance.addPostFrameCallback((_) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(poiProvider.errorMessage!), backgroundColor: Colors.red));
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
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12, bottom: 5, top: 5),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), child: widget.place.imageUrl.isNotEmpty ? Image.network(widget.place.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, size: 30, color: Colors.grey))) : Container(color: Colors.grey.shade200, child: Icon(Icons.image, size: 30, color: Colors.grey.shade400)))),
              Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(widget.place.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)), Text(widget.place.category, style: const TextStyle(fontSize: 10, color: Colors.grey))]))),
            ],
          ),
        ),
      ),
    );
  }
}