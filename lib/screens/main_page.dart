// lib/screens/main_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'dart:async';
import 'dart:ui'; // Indispensable pour l'effet de flou

import '../providers/city_provider.dart';
import '../providers/poi_provider.dart';
import '../providers/theme_provider.dart';
import '../services/database_service.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  String? _previousCityId;
  int _refreshKey = 0; 
  bool _showCarousel = false;
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
    _moveDebounce?.cancel();
    super.dispose();
  }

  void _refreshFavorites() => setState(() => _refreshKey++);

  void _onMapPositionChanged(dynamic position, bool hasGesture) {
    if (!hasGesture) return;
    final poiProvider = Provider.of<PoiProvider>(context, listen: false);
    if (poiProvider.activeCategory == null || poiProvider.activeCategory == 'favoris') return;

    if (_moveDebounce?.isActive ?? false) _moveDebounce!.cancel();

    _moveDebounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        final center = mapController.camera.center; 
        poiProvider.searchPois(center.latitude, center.longitude, poiProvider.activeCategory!, forceRefresh: true);
      }
    });
  }

  String _getWeatherAssetPath(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('pluie') || lower.contains('averse')) return 'assets/rain.json';
    if (lower.contains('neige')) return 'assets/snow.json';
    if (lower.contains('soleil') || lower.contains('clair') || lower.contains('clear')) return 'assets/sun.json';
    if (lower.contains('nuage') || lower.contains('couvert')) return 'assets/wind.json';
    return 'assets/wind.json';
  }

  // GESTION INTELLIGENTE DE L'AJOUT
  void _openAddPlaceDialog(LatLng location, {bool disableSearch = false}) {
    final currentCity = Provider.of<CityProvider>(context, listen: false).currentCity;
    final String cityName = currentCity?.name ?? 'Ville Inconnue';

    showDialog(
      context: context,
      builder: (ctx) => AddPlaceDialog(
        location: location, 
        cityName: cityName,
        disableSearch: disableSearch,
      ),
    ).then((added) {
      if (added == true) {
        _refreshFavorites();
      }
    });
  }

  // NAVIGATION "HERO" MAGNIFIQUE
  Future<void> _navigateToDetail(Place place) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PlaceDetailScreen(place: place),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), 
            child: child
          );
        },
        transitionDuration: const Duration(milliseconds: 700),
        reverseTransitionDuration: const Duration(milliseconds: 600),
      ),
    );
    _refreshFavorites();
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final isDark = themeProvider.themeMode == ThemeMode.dark;
        return AlertDialog(
          title: const Text("Paramètres"),
          content: SwitchListTile(
            title: const Text("Mode Sombre"),
            value: isDark,
            onChanged: (val) => themeProvider.toggleTheme(val),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Fermer"))],
        );
      },
    );
  }

  // --- WIDGETS UI ---

  // 1. BARRE DE RECHERCHE
  Widget _buildSearchBar(BuildContext context) {
    return Positioned(
      top: 50, left: 16, right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white70),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/search_city'),
                    child: Container(
                      color: Colors.transparent,
                      alignment: Alignment.centerLeft,
                      child: const Text('Rechercher une ville...', style: TextStyle(color: Colors.white60, fontSize: 16)),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.amber),
                  child: const Icon(Icons.search, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2. LISTE DES CATÉGORIES
  Widget _buildCategoriesList(BuildContext context, City city) {
    final categories = [
      {'key': 'favoris', 'icon': Icons.favorite, 'color': Colors.red, 'label': 'Favoris'},
      {'key': 'manger', 'icon': Icons.restaurant, 'color': Colors.orange, 'label': 'Manger'},
      {'key': 'cafés', 'icon': Icons.local_cafe, 'color': Colors.brown, 'label': 'Cafés'},
      {'key': 'culture', 'icon': Icons.museum, 'color': Colors.purple, 'label': 'Culture'},
      {'key': 'nature', 'icon': Icons.park, 'color': Colors.green, 'label': 'Nature'},
      {'key': 'shopping', 'icon': Icons.shopping_bag, 'color': Colors.pink, 'label': 'Shopping'},
      {'key': 'hôtels', 'icon': Icons.hotel, 'color': Colors.indigo, 'label': 'Hôtels'},
      {'key': 'santé', 'icon': Icons.local_pharmacy, 'color': Colors.teal, 'label': 'Santé'},
    ];

    return Positioned(
      top: 115, left: 0, right: 0,
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return Consumer<PoiProvider>(
              builder: (context, poiProvider, child) {
                final isSelected = poiProvider.activeCategory == cat['key'];
                return GestureDetector(
                  onTap: () {
                    // On passe cityName pour filtrer les favoris correctement si nécessaire
                    poiProvider.searchPois(city.latitude, city.longitude, cat['key'] as String, cityName: city.name);
                    setState(() => _showCarousel = !isSelected);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? (cat['color'] as Color) : Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat['icon'] as IconData, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          cat['label'] as String,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // 3. WIDGET MÉTÉO (Horizontal & Réactif)
  Widget _buildWeatherWidget(BuildContext context, City city) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double widgetWidth = screenWidth < 600 ? 280.0 : 320.0;

    return Positioned(
      top: 175, left: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: widgetWidth,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.5)]
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        city.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        city.weatherCondition,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${city.currentTemp.round()}°',
                        style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 50, width: 50,
                      child: Lottie.asset(_getWeatherAssetPath(city.weatherCondition), fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _weatherMiniInfo(Icons.water_drop, "${city.humidity}%"),
                        const SizedBox(width: 10),
                        _weatherMiniInfo(Icons.air, "${city.windSpeed.round()}"),
                        const SizedBox(width: 10),
                        _weatherMiniInfo(Icons.thermostat, "${city.maxTemp.round()}°"),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _weatherMiniInfo(IconData icon, String val) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 14),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // 4. LISTE DES FAVORIS (IMMERSIVE)
  Widget _buildLocalFavoritesList(BuildContext context, City city) {
    if (_showCarousel) return const SizedBox.shrink();

    return Positioned(
      bottom: 20, left: 0, right: 0, height: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_edu, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Carnet de voyage : ${city.name}",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Place>>(
              key: ValueKey(_refreshKey),
              future: DatabaseService.instance.getPlacesForCity(city.name),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                      child: const Text("Aucun lieu visité ici. Commencez l'exploration !", style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                    ),
                  );
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final place = snapshot.data![index];
                    return _AnimatedPlaceCard(place: place, onTap: () => _navigateToDetail(place));
                  },
                );
              },
            ),
          ),
        ],
      ),
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

        return Scaffold(
          key: _scaffoldKey,
          drawer: const CityDrawer(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 250),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 1. IA
                FloatingActionButton(
                  heroTag: "btn_ai", 
                  onPressed: () async {
                    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiAssistantScreen()));
                    if (result != null && result is Place) {
                      mapController.move(LatLng(result.latitude, result.longitude), 15.0);
                      _navigateToDetail(result);
                    }
                  },
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.amber,
                  elevation: 4,
                  child: const Icon(Icons.auto_awesome),
                ),
                const SizedBox(height: 16),
                
                // 2. SETTINGS
                FloatingActionButton(
                  heroTag: "btn_settings",
                  onPressed: _showSettingsDialog,
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.amber,
                  elevation: 4,
                  child: const Icon(Icons.settings),
                ),
                const SizedBox(height: 16),
                
                // 3. AJOUT
                FloatingActionButton(
                  heroTag: "btn_add",
                  onPressed: () => _openAddPlaceDialog(mapController.camera.center, disableSearch: false),
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  elevation: 6,
                  child: const Icon(Icons.add_location_alt),
                ),
              ],
            ),
          ),

          body: Stack(
            children: [
              Consumer<PoiProvider>(
                builder: (context, poiProvider, child) {
                  return FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: LatLng(city.latitude, city.longitude),
                      initialZoom: 13.0,
                      onLongPress: (_, point) => _openAddPlaceDialog(point, disableSearch: true),
                      onPositionChanged: _onMapPositionChanged, 
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                    ),
                    children: [
                      // ⚠️ CARTE AVEC FILTRE DARK MODE "NÉGATIF"
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.explorez_votre_ville',
                        tileBuilder: (context, widget, tile) {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          if (isDark) {
                            return ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                // Inversion des couleurs (Négatif) pour un effet sombre
                                -1,  0,  0, 0, 255,
                                 0, -1,  0, 0, 255,
                                 0,  0, -1, 0, 255,
                                 0,  0,  0, 1,   0,
                              ]),
                              child: widget,
                            );
                          }
                          return widget;
                        },
                      ),
                      MarkerLayer(
                        markers: poiProvider.currentPois.map((p) => Marker(
                          point: LatLng(p.latitude, p.longitude),
                          width: 50, height: 50,
                          child: GestureDetector(
                            onTap: () => _navigateToDetail(p.copyWith(cityName: city.name)),
                            child: const Icon(Icons.location_on, color: Colors.redAccent, size: 45),
                          ),
                        )).toList(),
                      ),
                    ],
                  );
                },
              ),
              _buildSearchBar(context),
              _buildCategoriesList(context, city),
              _buildWeatherWidget(context, city),
              _buildLocalFavoritesList(context, city),
              Consumer<PoiProvider>(
                builder: (context, poiProvider, child) {
                  if (_showCarousel && poiProvider.currentPois.isNotEmpty) {
                    return Positioned(
                      bottom: 30, left: 0, right: 0,
                      child: PoiCarousel(
                        places: poiProvider.currentPois,
                        onPlaceChanged: (p) => mapController.move(LatLng(p.latitude, p.longitude), 15.0),
                        onPlaceTap: (p) => _navigateToDetail(p.copyWith(cityName: city.name)),
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

class _AnimatedPlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  const _AnimatedPlaceCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180, 
        margin: const EdgeInsets.only(right: 15, bottom: 10), 
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'place-img-${place.title}',
                transitionOnUserGestures: true,
                child: place.imageUrl.isNotEmpty 
                  ? Image.network(place.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey.shade800))
                  : Container(color: Colors.grey.shade800, child: const Icon(Icons.image, color: Colors.white24, size: 50)),
              ),
              
              Positioned(
                bottom: 0, left: 0, right: 0, height: 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 12, left: 12, right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      place.title, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)])
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.category, color: Colors.amber, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.category.toUpperCase(), 
                            style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Positioned(
                top: 10, right: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.black.withOpacity(0.4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 4),
                          Material(
                            color: Colors.transparent,
                            child: Text(place.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
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