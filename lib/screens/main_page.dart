// lib/screens/main_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:ui';

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
import '../widgets/weather_card.dart';
import '../widgets/category_selector.dart';
import '../widgets/animated_place_card.dart';
import '../widgets/floating_menu.dart';

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

  // --- ACTIONS ---

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

  // --- MODIFICATION ICI : BOÎTE DE DIALOGUE PARAMÈTRES ---
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final isDark = themeProvider.themeMode == ThemeMode.dark;
        
        return AlertDialog(
          title: const Text("Paramètres"),
          // On utilise Column avec mainAxisSize.min pour empiler les options
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Option 1 : Thème
              SwitchListTile(
                title: const Text("Mode Sombre"),
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                value: isDark,
                onChanged: (val) => themeProvider.toggleTheme(val),
              ),
              
              const Divider(),
              
              // Option 2 : Supprimer la ville par défaut
              ListTile(
                leading: const Icon(Icons.location_off, color: Colors.redAccent),
                title: const Text("Oublier la ville par défaut"),
                subtitle: const Text("Au prochain lancement, l'app redemandera votre position."),
                onTap: () async {
                  // Appel au service pour supprimer la préférence
                  await PreferencesService().clearDefaultCity();
                  
                  if (mounted) {
                    Navigator.pop(ctx); // Fermer le dialogue
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Ville par défaut supprimée."),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text("Fermer")
            )
          ],
        );
      },
    );
  }

  Future<void> _handleAiAssistant() async {
    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiAssistantScreen()));
    if (result != null && result is Place) {
      mapController.move(LatLng(result.latitude, result.longitude), 15.0);
      _navigateToDetail(result);
    }
  }

  // --- SOUS-WIDGETS LOCAUX ---

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
                    return AnimatedPlaceCard(
                        place: place,
                        onTap: () => _navigateToDetail(place)
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
          
          floatingActionButton: FloatingMenu(
            onAiPressed: _handleAiAssistant,
            onSettingsPressed: _showSettingsDialog,
            onAddPressed: () => _openAddPlaceDialog(mapController.camera.center, disableSearch: false),
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
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.explorez_votre_ville',
                        tileBuilder: (context, widget, tile) {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          if (isDark) {
                            return ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
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
              Positioned(
                top: 115, left: 0, right: 0,
                child: CategorySelector(
                  city: city,
                  onCategoryTap: (showCarousel) {
                    setState(() => _showCarousel = showCarousel);
                  },
                ),
              ),
              Positioned(
                top: 175, left: 16,
                child: WeatherCard(city: city),
              ),
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