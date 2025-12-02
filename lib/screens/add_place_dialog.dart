// lib/screens/add_place_dialog.dart

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/place_model.dart';
import '../services/database_service.dart';
import '../services/geoloc_service.dart';
import '../services/places_service.dart';

class AddPlaceDialog extends StatefulWidget {
  final LatLng location;
  final String cityName;
  final Place? placeToEdit;

  const AddPlaceDialog({
    super.key, 
    required this.location, 
    required this.cityName,
    this.placeToEdit,
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
  
  // Localisation
  late double _currentLat;
  late double _currentLng;
  
  // ⚠️ NOUVEAU : Variables pour stocker les infos riches récupérées
  String _fetchedImageUrl = '';
  double _fetchedRating = 0.0;
  int _fetchedNoteCount = 0;
  String _googlePlaceId = ''; // On garde le vrai ID Google si trouvé

  bool _isFetching = false;
  String _addressPreview = "Position sélectionnée sur la carte";

  final List<String> _categories = [
    'Musée', 'Salle de concert', 'Théâtre', 'Cinéma', 
    'Parc', 'Stade', 'Restaurant', 'Café', 'Autre'
  ];

  @override
  void initState() {
    super.initState();
    
    _currentLat = widget.location.latitude;
    _currentLng = widget.location.longitude;

    if (widget.placeToEdit != null) {
      // Mode Édition : On reprend tout ce qu'on a déjà
      _nameController = TextEditingController(text: widget.placeToEdit!.title);
      _selectedCategory = _categories.contains(widget.placeToEdit!.category) 
          ? widget.placeToEdit!.category 
          : 'Autre';
      _addressPreview = widget.placeToEdit!.description;
      
      // ⚠️ On initialise avec les valeurs existantes
      _fetchedImageUrl = widget.placeToEdit!.imageUrl;
      _fetchedRating = widget.placeToEdit!.rating;
      _fetchedNoteCount = widget.placeToEdit!.noteCount;
      
    } else {
      // Mode Création
      _nameController = TextEditingController();
      _selectedCategory = 'Autre';
      // On cherche l'adresse par défaut (Reverse Geocoding)
      _fetchAddressFromCoordinates();
    }
  }

  // Chercher adresse depuis coordonnées (Mode "Sélection Carte")
  Future<void> _fetchAddressFromCoordinates() async {
    // Si on a déjà une image (donc un lieu Google identifié), on ne refait pas de géocodage inverse basique
    if (_fetchedImageUrl.isNotEmpty) return;

    setState(() => _isFetching = true);
    try {
      final data = await _geolocService.reverseGeocode(_currentLat, _currentLng);
      if (mounted) {
        setState(() {
          _addressPreview = "Adresse : ${data['city']}"; 
        });
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  // ⚠️ RECHERCHE INTELLIGENTE ET RÉCUPÉRATION DES INFOS
  Future<void> _searchPlaceByText() async {
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
          // 1. Mises à jour de base
          _currentLat = foundPlace.latitude;
          _currentLng = foundPlace.longitude;
          _nameController.text = foundPlace.title; 
          _addressPreview = foundPlace.description;
          
          if (_categories.contains(foundPlace.category)) {
            _selectedCategory = foundPlace.category;
          }

          // ⚠️ 2. RÉCUPÉRATION DES INFOS RICHES (Image, Note, ID)
          _fetchedImageUrl = foundPlace.imageUrl;
          _fetchedRating = foundPlace.rating;
          _fetchedNoteCount = foundPlace.noteCount;
          _googlePlaceId = foundPlace.placeId; // On garde l'ID Google pour récupérer le tel/site web plus tard
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lieu trouvé ! Infos et Image récupérées.")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Aucun lieu trouvé avec ce nom.")),
          );
        }
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _savePlace() async {
    if (_formKey.currentState!.validate()) {
      // Si on a trouvé un ID Google via la recherche, on l'utilise !
      // Sinon, on génère un ID manuel.
      String idToSave;
      if (_googlePlaceId.isNotEmpty) {
        idToSave = _googlePlaceId; // Utilise l'ID Google (permettra d'avoir tel/site web dans le détail)
      } else {
        idToSave = widget.placeToEdit != null 
            ? widget.placeToEdit!.placeId 
            : 'manual_${DateTime.now().millisecondsSinceEpoch}';
      }

      final double userRating = widget.placeToEdit?.userRating ?? 0.0;
      final String? userComment = widget.placeToEdit?.userComment;

      final placeToSave = Place(
        placeId: idToSave,
        cityName: widget.cityName,
        title: _nameController.text,
        description: _addressPreview,
        category: _selectedCategory,
        latitude: _currentLat,
        longitude: _currentLng,
        // ⚠️ ON SAUVEGARDE L'IMAGE ET LA NOTE RÉCUPÉRÉES
        imageUrl: _fetchedImageUrl, 
        rating: _fetchedRating,
        noteCount: _fetchedNoteCount,
        userRating: userRating,
        userComment: userComment,
      );

      await DatabaseService.instance.insertPlace(placeToSave);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.placeToEdit != null ? "Lieu modifié" : "Lieu ajouté avec succès")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.placeToEdit != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier le lieu' : 'Ajouter un lieu'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ⚠️ APERÇU DE L'IMAGE SI TROUVÉE
              if (_fetchedImageUrl.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: NetworkImage(_fetchedImageUrl),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 5)],
                  ),
                  child: Stack(
                    children: [
                      // Badge Note Google
                      if (_fetchedRating > 0)
                        Positioned(
                          top: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 12, color: Colors.black),
                                const SizedBox(width: 4),
                                Text(_fetchedRating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // Champ Nom + Recherche
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom du lieu (ex: Le Louvre)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.place),
                  suffixIcon: IconButton(
                    icon: _isFetching 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search, color: Colors.blue),
                    onPressed: _searchPlaceByText,
                    tooltip: "Rechercher les infos sur Google",
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                onFieldSubmitted: (_) => _searchPlaceByText(),
              ),
              
              const SizedBox(height: 10),
              
              // Adresse
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _addressPreview,
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),
              
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        ElevatedButton(onPressed: _savePlace, child: Text(isEditing ? 'Sauvegarder' : 'Ajouter')),
      ],
    );
  }
}