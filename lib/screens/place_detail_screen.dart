// lib/screens/place_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../models/place_model.dart';
import '../services/places_service.dart';
import '../services/database_service.dart';
import 'note_comment_dialog.dart';
import 'add_place_dialog.dart'; // ⚠️ Import nécessaire pour la modif

class PlaceDetailScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailScreen({super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final PlacesService _placesService = PlacesService();
  late Place _currentPlace;

  bool _isLoadingDetails = true;
  String? _phoneNumber;
  String? _website;
  bool _isOpenNow = false;
  bool _isFavorite = false; 

  @override
  void initState() {
    super.initState();
    _currentPlace = widget.place;
    _checkFavoriteStatus();
    _loadExtraDetails();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await DatabaseService.instance.isPlaceFavorite(_currentPlace.placeId);
    if (isFav) {
      final savedPlaces = await DatabaseService.instance.getAllPlaces();
      try {
        final savedPlace = savedPlaces.firstWhere((p) => p.placeId == _currentPlace.placeId);
        if (mounted) {
          setState(() {
            _currentPlace = savedPlace;
            _isFavorite = true;
          });
        }
      } catch (e) { /* ID introuvable */ }
    } else {
      if (mounted) setState(() => _isFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await DatabaseService.instance.deletePlace(_currentPlace.placeId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Retiré des favoris")));
    } else {
      await DatabaseService.instance.insertPlace(_currentPlace);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ajouté aux favoris !")));
    }
    setState(() => _isFavorite = !_isFavorite);
  }

  Future<void> _loadExtraDetails() async {
    if (_currentPlace.placeId.isEmpty || _currentPlace.placeId.startsWith('manual_')) {
      setState(() => _isLoadingDetails = false);
      return; 
    }
    final details = await _placesService.fetchPlaceDetails(_currentPlace.placeId);
    if (mounted) {
      setState(() {
        _phoneNumber = details['formatted_phone_number'];
        _website = details['website'];
        if (details['opening_hours'] != null) {
          _isOpenNow = details['opening_hours']['open_now'] ?? false;
        }
        _isLoadingDetails = false;
      });
    }
  }

  Future<void> _openNoteDialog() async {
    if (!_isFavorite) {
      await DatabaseService.instance.insertPlace(_currentPlace);
      setState(() => _isFavorite = true);
    }
    final Place? updatedPlace = await showDialog<Place>(
      context: context,
      builder: (ctx) => NoteCommentDialog(place: _currentPlace),
    );
    if (updatedPlace != null && mounted) {
      setState(() {
        _currentPlace = updatedPlace;
      });
    }
  }

  // ⚠️ FONCTION DE MODIFICATION (Pour les lieux manuels)
  Future<void> _editManualPlace() async {
    final bool? modified = await showDialog(
      context: context,
      builder: (ctx) => AddPlaceDialog(
        location: LatLng(_currentPlace.latitude, _currentPlace.longitude),
        cityName: _currentPlace.cityName,
        placeToEdit: _currentPlace, // On passe le lieu actuel
      ),
    );

    if (modified == true) {
      // Recharger depuis la BD pour avoir le nouveau titre/catégorie
      _checkFavoriteStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Vérifie si c'est un lieu manuel
    final bool isManual = _currentPlace.placeId.startsWith('manual_');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          // ⚠️ BOUTON EDIT (Seulement si manuel)
          if (isManual)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.edit_location_alt, color: Colors.amber),
                onPressed: _editManualPlace,
                tooltip: "Modifier les infos",
              ),
            ),

          Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : Colors.white),
              onPressed: _toggleFavorite, 
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'place-img-${_currentPlace.title}',
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                    child: _currentPlace.imageUrl.isNotEmpty
                        ? Image.network(_currentPlace.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)))
                        : const Icon(Icons.image, size: 100, color: Colors.grey),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)])),
                  ),
                ),
              ],
            ),
            
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 0.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutExpo,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value * 100),
                  child: Opacity(
                    opacity: 1 - value,
                    child: child,
                  ),
                );
              },
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _currentPlace.title,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (!isManual) // Affiche la note Google seulement si ce n'est pas manuel
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, size: 16, color: Colors.black),
                                  const SizedBox(width: 4),
                                  Text(_currentPlace.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Catégorie
                      Text(_currentPlace.category.toUpperCase(), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      
                      const SizedBox(height: 15),
                      
                      if (!_isLoadingDetails && _isOpenNow)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                          child: const Text("OUVERT ACTUELLEMENT", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),

                      const Divider(),
                      
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_on, color: Colors.blue),
                        title: Text(_currentPlace.description),
                      ),

                      if (_isLoadingDetails)
                        const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                      else ...[
                        if (_phoneNumber != null)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.phone, color: Colors.green),
                            title: Text(_phoneNumber!),
                            onTap: () async {
                               final Uri url = Uri.parse("tel:$_phoneNumber");
                               if (await canLaunchUrl(url)) await launchUrl(url);
                            },
                          ),
                        if (_website != null)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.public, color: Colors.purple),
                            title: Text(_website!, style: const TextStyle(decoration: TextDecoration.underline, color: Colors.blue)),
                            onTap: () async {
                               final Uri url = Uri.parse(_website!);
                               if (await canLaunchUrl(url)) await launchUrl(url);
                            },
                          ),
                      ],

                      const SizedBox(height: 20),
                      const Text("Localisation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(_currentPlace.latitude, _currentPlace.longitude),
                              initialZoom: 15.0,
                              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.explorez_votre_ville',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(_currentPlace.latitude, _currentPlace.longitude),
                                    width: 40, height: 40,
                                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(thickness: 1.5),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Votre avis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          if (_currentPlace.userRating != null && _currentPlace.userRating! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                children: [
                                  Text(_currentPlace.userRating.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.star, size: 16, color: Colors.blue.shade900),
                                ],
                              ),
                            )
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      if (_currentPlace.userComment != null && _currentPlace.userComment!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            _currentPlace.userComment!,
                            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                          ),
                        )
                      else 
                        const Padding(
                          padding: EdgeInsets.only(bottom: 15),
                          child: Text("Vous n'avez pas encore commenté ce lieu.", style: TextStyle(color: Colors.grey)),
                        ),

                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _openNoteDialog,
                          icon: const Icon(Icons.edit),
                          label: Text(_currentPlace.userComment != null ? "Modifier ma note" : "Ajouter une note personnelle"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}