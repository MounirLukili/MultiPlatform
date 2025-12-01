// lib/screens/add_place_dialog.dart

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/place_model.dart';
import '../services/database_service.dart';

class AddPlaceDialog extends StatefulWidget {
  final LatLng location; // La position sélectionnée sur la carte
  final String cityName; // ⚠️ 1. On ajoute ce paramètre

const AddPlaceDialog({
    super.key, 
    required this.location, 
    required this.cityName // ⚠️
  });
  @override
  State<AddPlaceDialog> createState() => _AddPlaceDialogState();
}

class _AddPlaceDialogState extends State<AddPlaceDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  
  // Liste des catégories demandées
  final List<String> _categories = [
    'Musée', 
    'Salle de concert', 
    'Théâtre', 
    'Cinéma', 
    'Parc', 
    'Stade', 
    'Restaurant', 
    'Autre'
  ];
  String _selectedCategory = 'Autre';

  Future<void> _savePlace() async {
   if (_formKey.currentState!.validate()) {
      final String manualId = 'manual_${DateTime.now().millisecondsSinceEpoch}';

      final newPlace = Place(
        placeId: manualId,
        cityName: widget.cityName, // ⚠️ 2. On utilise le vrai nom de la ville ici !
        title: _nameController.text,
        description: 'Lieu ajouté manuellement',
        category: _selectedCategory,
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        imageUrl: '',
        rating: 0.0,
        noteCount: 0,
        userRating: 0.0,
        userComment: '',
      );

      // 2. Sauvegarde dans SQLite
      await DatabaseService.instance.insertPlace(newPlace);

      if (mounted) {
        Navigator.of(context).pop(true); // Renvoie true pour dire "Succès"
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lieu "${newPlace.title}" ajouté aux favoris !')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un lieu'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Champ NOM
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du lieu (ex: Le Louvre)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Entrez un nom' : null,
              ),
              const SizedBox(height: 15),

              // Champ CATÉGORIE
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 15),

              // Affichage LOCALISATION (lecture seule pour confirmation)
              Row(
                children: [
                  const Icon(Icons.map, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Position : ${widget.location.latitude.toStringAsFixed(4)}, ${widget.location.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _savePlace,
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}