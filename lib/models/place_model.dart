// lib/models/place_model.dart
// Modèle de données pour un lieu d'intérêt (POI) stocké dans SQLite.

class Place {
  // L'ID auto-incrémenté dans SQLite
  final int? id; 
  // Clé étrangère implicite pour lier le lieu à une ville
  final String cityName; 
  
  final String title;
  final String description;
  final String category; // ex: 'Musée', 'Restaurant', 'Parc'
  final double latitude;
  final double longitude;
  final String imageUrl; // URL ou chemin d'asset pour l'image
  
  final double rating; // Note moyenne
  final int noteCount; // Nombre de notes/commentaires

  Place({
    this.id,
    required this.cityName,
    required this.title,
    this.description = '',
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    this.rating = 0.0,
    this.noteCount = 0,
  });

  // Convertit un objet Place en Map pour insertion/mise à jour dans SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cityName': cityName,
      'title': title,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'rating': rating,
      'noteCount': noteCount,
    };
  }

  // Crée un objet Place à partir d'un Map (lu depuis SQLite)
  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      id: map['id'] as int?,
      cityName: map['cityName'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      imageUrl: map['imageUrl'] as String,
      // Conversion sécurisée des nombres (stocké en REAL/INTEGER dans SQLite)
      rating: map['rating'] as double? ?? 0.0,
      noteCount: map['noteCount'] as int? ?? 0,
    );
  }

  // Pour le débogage
  @override
  String toString() {
    return 'Place(id: $id, title: $title, city: $cityName)';
  }
}