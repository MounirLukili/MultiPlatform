// lib/models/city_model.dart

import 'package:flutter/foundation.dart'; // <-- nécessaire pour UniqueKey

class City {
  // Identifiant unique pour détecter les changements
  final String id;

  // Informations de base
  final String name;
  final String country;
  // Coordonnées géographiques
  final double latitude;
  final double longitude;
  // Informations Météo (stockées pour cette ville)
  final double currentTemp;
  final double minTemp;
  final double maxTemp;
  final String weatherCondition; // ex: 'Ensoleillé', 'Pluvieux'
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
  // (utilisée lors de la recherche par coordonnées avant l'appel à l'API météo)
  factory City.fromCoordinates({
    required String name,
    required String country,
    required double latitude,
    required double longitude,
  }) {
    // Génère un id unique à chaque création (utile pour forcer la détection de changement)
    final String generatedId = UniqueKey().toString();

    // Initialisation par défaut de la météo en attendant l'appel API
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

  // Méthode pour créer une nouvelle instance de City avec les données météo mises à jour
  // Utile pour la fonction copyWith() standard.
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

  // Optionnel : méthode pour forcer explicitement la création d'une copie avec un nouvel id
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
      // Valeurs par défaut pour la météo (sera rechargée par l'API)
      currentTemp: 0.0,
      minTemp: 0.0,
      maxTemp: 0.0,
      weatherCondition: 'Chargement...',
      humidity: 0,
      windSpeed: 0.0,
    );
  }

}
