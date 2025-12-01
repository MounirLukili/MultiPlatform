// lib/screens/place_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../models/place_model.dart';
import '../services/places_service.dart';
import '../services/database_service.dart'; // ⚠️ IMPORT SQLITE

class PlaceDetailScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailScreen({super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final PlacesService _placesService = PlacesService();
  
  // États pour les détails API
  bool _isLoadingDetails = true;
  String? _phoneNumber;
  String? _website;
  bool _isOpenNow = false;

  // État pour les Favoris (SQLite)
  bool _isFavorite = false; 

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _loadExtraDetails();
  }

  // 1. Vérifier si le lieu est déjà en favori dans la BD
  Future<void> _checkFavoriteStatus() async {
    final isFav = await DatabaseService.instance.isPlaceFavorite(widget.place.placeId);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  // 2. Basculer l'état favori AVEC DEBUG
  Future<void> _toggleFavorite() async {
    // A. Action Base de données
    if (_isFavorite) {
      await DatabaseService.instance.deletePlace(widget.place.placeId);
      print("🗑️ DEBUG: Lieu supprimé de SQLite : ${widget.place.title}"); // DEBUG
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Retiré des favoris")),
        );
      }
    } else {
      await DatabaseService.instance.insertPlace(widget.place);
      print("💾 DEBUG: Lieu ajouté dans SQLite : ${widget.place.title}"); // DEBUG

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ajouté aux favoris !")),
        );
      }
    }

    // B. Mettre à jour l'UI (cœur rouge/blanc)
    setState(() {
      _isFavorite = !_isFavorite;
    });

    // C. 🔍 VERIFICATION DEBUG : Lire tout le contenu de la base
    print("----------------------------------------------------------");
    print("🔍 DEBUG: Lecture de la table 'places'...");
    final allPlaces = await DatabaseService.instance.getAllPlaces();
    
    if (allPlaces.isEmpty) {
      print("📭 La base de données est VIDE.");
    } else {
      print("📂 La base contient ${allPlaces.length} favoris :");
      for (var p in allPlaces) {
        print("   - [ID: ${p.placeId}] ${p.title} (Ville: ${p.cityName})");
      }
    }
    print("----------------------------------------------------------");
  }

  Future<void> _loadExtraDetails() async {
    if (widget.place.placeId.isEmpty) return;

    final details = await _placesService.fetchPlaceDetails(widget.place.placeId);
    
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

  @override
  Widget build(BuildContext context) {
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
          // BOUTON FAVORIS
          Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.white,
              ),
              onPressed: _toggleFavorite, 
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE HERO
            Stack(
              children: [
                Hero(
                  tag: 'place-img-${widget.place.title}',
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                    child: widget.place.imageUrl.isNotEmpty
                        ? Image.network(
                            widget.place.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, error, stack) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                          )
                        : const Icon(Icons.image, size: 100, color: Colors.grey),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // CONTENU DÉTAILS
            Transform.translate(
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
                    // Titre et Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.place.title,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.black),
                              const SizedBox(width: 4),
                              Text(widget.place.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    // Statut Ouvert
                    if (!_isLoadingDetails && _isOpenNow)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                        child: const Text("OUVERT ACTUELLEMENT", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),

                    const Divider(),
                    
                    // Adresse / Description
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on, color: Colors.blue),
                      title: Text(widget.place.description),
                    ),

                    // Infos supplémentaires (Tel / Web)
                    if (_isLoadingDetails)
                      const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                    else ...[
                      if (_phoneNumber != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.phone, color: Colors.green),
                          title: Text(_phoneNumber!),
                          onTap: () async {
                             // Exemple d'ouverture URL
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
                             // Exemple d'ouverture URL
                             final Uri url = Uri.parse(_website!);
                             if (await canLaunchUrl(url)) await launchUrl(url);
                          },
                        ),
                    ],

                    const SizedBox(height: 20),
                    const Text("Vos notes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fonctionnalité commentaire à venir !")));
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text("Ajouter une note personnelle"),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}