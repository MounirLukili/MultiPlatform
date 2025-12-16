import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui';
import '../models/place_model.dart';
import '../services/database_service.dart';
import '../services/geoloc_service.dart';
import '../services/places_service.dart';
import '../widgets/dialog_header_image.dart';
import '../widgets/category_chips_selector.dart';

class AddPlaceDialog extends StatefulWidget {
  final LatLng location;
  final String cityName;
  final Place? placeToEdit;
  final bool disableSearch;

  const AddPlaceDialog({
    super.key, 
    required this.location, 
    required this.cityName,
    this.placeToEdit,
    this.disableSearch = false,
  });

  @override
  State<AddPlaceDialog> createState() => _AddPlaceDialogState();
}

class _AddPlaceDialogState extends State<AddPlaceDialog> {
  final _formKey = GlobalKey<FormState>();
  final GeolocService _geolocService = GeolocService();
  final PlacesService _placesService = PlacesService();

  late TextEditingController _nameController;
  late String _selectedCategory;
  
  late double _currentLat;
  late double _currentLng;
  String _fetchedImageUrl = '';
  double _fetchedRating = 0.0;
  int _fetchedNoteCount = 0;
  String _googlePlaceId = '';
  
  bool _isFetching = false;
  String _addressPreview = "Position sélectionnée";

  final Map<String, IconData> _categories = {
    'Manger': Icons.restaurant,
    'Café': Icons.local_cafe,
    'Musée': Icons.museum,
    'Parc': Icons.park,
    'Shopping': Icons.shopping_bag,
    'Hôtel': Icons.hotel,
    'Santé': Icons.local_pharmacy,
    'Autre': Icons.bookmark,
  };

  @override
  void initState() {
    super.initState();
    _currentLat = widget.location.latitude;
    _currentLng = widget.location.longitude;

    if (widget.placeToEdit != null) {
      _nameController = TextEditingController(text: widget.placeToEdit!.title);
      _selectedCategory = widget.placeToEdit!.category;
      _addressPreview = widget.placeToEdit!.description;
      _fetchedImageUrl = widget.placeToEdit!.imageUrl;
      _fetchedRating = widget.placeToEdit!.rating;
      _fetchedNoteCount = widget.placeToEdit!.noteCount;
    } else {
      _nameController = TextEditingController();
      _selectedCategory = 'Autre';
      _fetchAddressFromCoordinates();
    }
  }

  Future<void> _fetchAddressFromCoordinates() async {
    if (_fetchedImageUrl.isNotEmpty) return;
    setState(() => _isFetching = true);
    try {
      final data = await _geolocService.reverseGeocode(_currentLat, _currentLng);
      if (mounted) {
        setState(() {
          final address = data['address'] ?? {};
          final road = address['road'] ?? address['pedestrian'] ?? '';
          final city = address['city'] ?? address['town'] ?? widget.cityName;
          _addressPreview = road.isNotEmpty ? "$road, $city" : city;
        });
      }
    } catch (e) { /* ignore */ } 
    finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _searchPlaceByText() async {
    if (widget.disableSearch) return;
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isFetching = true);
    FocusScope.of(context).unfocus();

    try {
      final Place? foundPlace = await _placesService.searchPlaceByText(
        _nameController.text, 
        _currentLat, 
        _currentLng
      );

      if (foundPlace != null) {
        setState(() {
          _currentLat = foundPlace.latitude;
          _currentLng = foundPlace.longitude;
          _nameController.text = foundPlace.title; 
          _addressPreview = foundPlace.description;
          _fetchedImageUrl = foundPlace.imageUrl;
          _fetchedRating = foundPlace.rating;
          _fetchedNoteCount = foundPlace.noteCount;
          _googlePlaceId = foundPlace.placeId;
        });
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _savePlace() async {
    if (_formKey.currentState!.validate()) {
      String idToSave = _googlePlaceId.isNotEmpty 
          ? _googlePlaceId 
          : (widget.placeToEdit?.placeId ?? 'manual_${DateTime.now().millisecondsSinceEpoch}');

      final placeToSave = Place(
        placeId: idToSave,
        cityName: widget.cityName,
        title: _nameController.text,
        description: _addressPreview,
        category: _selectedCategory.toLowerCase(),
        latitude: _currentLat,
        longitude: _currentLng,
        imageUrl: _fetchedImageUrl, 
        rating: _fetchedRating,
        noteCount: _fetchedNoteCount,
        userRating: widget.placeToEdit?.userRating,
        userComment: widget.placeToEdit?.userComment,
      );

      await DatabaseService.instance.insertPlace(placeToSave);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withOpacity(0.95),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))
              ]
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DialogHeaderImage(
                    imageUrl: _fetchedImageUrl,
                    category: _selectedCategory,
                    rating: _fetchedRating,
                    categoryIcon: _categories[_selectedCategory] ?? Icons.place,
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNameField(),
                          
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.amber, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _addressPreview,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text("CATÉGORIE", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 10),
                          
                          CategoryChipsSelector(
                            categories: _categories,
                            selectedCategory: _selectedCategory,
                            onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
                          ),

                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Annuler", style: TextStyle(color: Colors.white54)),
                                ),
                              ),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _savePlace,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                  child: Text(widget.placeToEdit != null ? "MODIFIER" : "ENREGISTRER", style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: TextFormField(
        controller: _nameController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: widget.disableSearch ? "Nom du repère (ex: Mon coin secret)" : "Rechercher un lieu (ex: Tour Eiffel)",
          hintStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          suffixIcon: widget.disableSearch 
              ? const Icon(Icons.edit, color: Colors.white54)
              : IconButton(
                  icon: _isFetching 
                      ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber))
                      : const Icon(Icons.search, color: Colors.amber),
                  onPressed: _searchPlaceByText,
                ),
        ),
        onFieldSubmitted: widget.disableSearch ? null : (_) => _searchPlaceByText(),
        validator: (v) => v == null || v.isEmpty ? 'Le nom est requis' : null,
      ),
    );
  }
}