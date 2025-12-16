import 'package:flutter/foundation.dart'; 

class City {

  final String id;
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final double currentTemp;
  final double minTemp;
  final double maxTemp;
  final String weatherCondition; 
  final int humidity;
  final double windSpeed;

  City({
    required this.id,
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.currentTemp,
    required this.minTemp,
    required this.maxTemp,
    required this.weatherCondition,
    required this.humidity,
    required this.windSpeed,
  });

  // Méthode de commodité pour créer une ville sans les données météo initiales 
  factory City.fromCoordinates({
    required String name,
    required String country,
    required double latitude,
    required double longitude,
  }) {
    // Génère un id unique à chaque création (pr detecter le changement)
    final String generatedId = UniqueKey().toString();

    // Init  de la météo en attendant l' API
    return City(
      id: generatedId,
      name: name,
      country: country,
      latitude: latitude,
      longitude: longitude,
      currentTemp: 0.0,
      minTemp: 0.0,
      maxTemp: 0.0,
      weatherCondition: 'Chargement...',
      humidity: 0,
      windSpeed: 0.0,
    );
  }

  // Méthode pour créer une nouvelle instance de laville avec les données meteo
  
  City copyWithWeather({
    required double currentTemp,
    required double minTemp,
    required double maxTemp,
    required String weatherCondition,
    required int humidity,
    required double windSpeed,
  }) {
    return City(
      id: id, // conserve l'ID existant (ou remplace si tu veux forcer un nouvel ID)
      name: name,
      country: country,
      latitude: latitude,
      longitude: longitude,
      currentTemp: currentTemp,
      minTemp: minTemp,
      maxTemp: maxTemp,
      weatherCondition: weatherCondition,
      humidity: humidity,
      windSpeed: windSpeed,
    );
  }

  // méthode pour forcer  la création d'une copie avec un nouvel id
  City copyWithNewId() {
    return City(
      id: UniqueKey().toString(),
      name: name,
      country: country,
      latitude: latitude,
      longitude: longitude,
      currentTemp: currentTemp,
      minTemp: minTemp,
      maxTemp: maxTemp,
      weatherCondition: weatherCondition,
      humidity: humidity,
      windSpeed: windSpeed,
    );
  }

  // Permet de faciliter le débogage et l'affichage des informations
  @override
  String toString() {
    return 'City(id: $id, name: $name, country: $country, lat: $latitude, lon: $longitude, temp: ${currentTemp.round()}°, condition: $weatherCondition)';
  }

  // Convertir une City en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Créer une City depuis SQLite
  factory City.fromMap(Map<String, dynamic> map) {
    return City(
      id: map['id'],
      name: map['name'],
      country: map['country'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      // Valeurs par defaut pour la meteo (API)
      currentTemp: 0.0,
      minTemp: 0.0,
      maxTemp: 0.0,
      weatherCondition: 'Chargement...',
      humidity: 0,
      windSpeed: 0.0,
    );
  }

}
