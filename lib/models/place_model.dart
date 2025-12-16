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
  final String placeId; 
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
      userComment: map['userComment'] as String?,
      userRating: map['userRating'] as double?,
    );
  }


  //  Méthode pour cloner un lieu en modifiant certains champs
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
      id: id, 
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
}