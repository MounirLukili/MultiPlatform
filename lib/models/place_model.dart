// lib/models/place_model.dart

class Place {
  final int? id; 
  final String cityName; 
  final String title;
  final String description;
  final String category;
  final double latitude;
  final double longitude;
  final String imageUrl; 
  final double rating; 
  final int noteCount;
  
  // L'identifiant unique Google (ex: "ChIJ...")
  final String placeId; 

  // ⚠️ AJOUTS OBLIGATOIRES POUR SQLITE (Commentaires & Notes perso)
  // Ces champs ne sont pas 'final' car on peut vouloir les modifier après chargement
  String? userComment;
  double? userRating;

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
    required this.placeId,
    // ⚠️ On les ajoute au constructeur
    this.userComment,
    this.userRating,
  });

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
      'placeId': placeId,
      // ⚠️ On les ajoute au mappage vers la BDD
      'userComment': userComment,
      'userRating': userRating,
    };
  }

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
      rating: map['rating'] as double? ?? 0.0,
      noteCount: map['noteCount'] as int? ?? 0,
      placeId: map['placeId'] as String? ?? '',
      // ⚠️ On les récupère depuis la BDD
      userComment: map['userComment'] as String?,
      userRating: map['userRating'] as double?,
    );
  }

  // ... (Constructeurs et autres méthodes existants)

  // ⚠️ AJOUT : Méthode pour cloner un lieu en modifiant certains champs
  Place copyWith({
    String? placeId,
    String? cityName,
    String? title,
    String? description,
    String? category,
    double? latitude,
    double? longitude,
    String? imageUrl,
    double? rating,
    int? noteCount,
    String? userComment,
    double? userRating,
  }) {
    return Place(
      id: id, // On garde le même ID interne
      placeId: placeId ?? this.placeId,
      cityName: cityName ?? this.cityName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      noteCount: noteCount ?? this.noteCount,
      userComment: userComment ?? this.userComment,
      userRating: userRating ?? this.userRating,
    );
  }
// ... (Reste du fichier)
}