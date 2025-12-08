// lib/screens/place_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/place_model.dart';
import '../services/places_service.dart';
import '../services/database_service.dart';
import 'note_comment_dialog.dart';
import 'add_place_dialog.dart';

// IMPORTS DES NOUVEAUX WIDGETS
import '../widgets/place_header_image.dart';
import '../widgets/place_contact_info.dart';
import '../widgets/place_map_preview.dart';
import '../widgets/place_user_review.dart';

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

  Future<void> _editManualPlace() async {
    final bool? modified = await showDialog(
      context: context,
      builder: (ctx) => AddPlaceDialog(
        location: LatLng(_currentPlace.latitude, _currentPlace.longitude),
        cityName: _currentPlace.cityName,
        placeToEdit: _currentPlace,
      ),
    );

    if (modified == true) {
      _checkFavoriteStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // 1. WIDGET IMAGE
            PlaceHeaderImage(place: _currentPlace),

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
                          if (!isManual)
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
                      Text(_currentPlace.category.toUpperCase(), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),

                      const SizedBox(height: 15),

                      // 2. WIDGET CONTACT INFO
                      PlaceContactInfo(
                        description: _currentPlace.description,
                        phoneNumber: _phoneNumber,
                        website: _website,
                        isLoading: _isLoadingDetails,
                        isOpenNow: _isOpenNow,
                      ),

                      const SizedBox(height: 20),

                      // 3. WIDGET CARTE
                      PlaceMapPreview(
                        latitude: _currentPlace.latitude,
                        longitude: _currentPlace.longitude,
                      ),

                      const SizedBox(height: 20),

                      // 4. WIDGET AVIS UTILISATEUR
                      PlaceUserReview(
                        place: _currentPlace,
                        onEditPressed: _openNoteDialog,
                      ),
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