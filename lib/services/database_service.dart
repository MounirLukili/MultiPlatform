// lib/services/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart'; // ⚠️ NOUVEAU : Pour kIsWeb
import '../models/place_model.dart';
import '../models/city_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('explore_ville_v1.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;

    // ⚠️ CORRECTION PERSISTANCE WEB
    if (kIsWeb) {
      // Sur le Web, on donne juste le nom du fichier.
      // Cela permet à sqflite_common_ffi_web de le stocker dans IndexedDB (persistant).
      path = filePath;
    } else {
      // Sur Mobile/Desktop, on utilise le chemin système correct.
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path, 
      version: 1, 
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Table des Lieux (POI)
    await db.execute('''
      CREATE TABLE places (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        placeId TEXT NOT NULL UNIQUE,
        cityName TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        imageUrl TEXT NOT NULL,
        rating REAL NOT NULL,
        noteCount INTEGER NOT NULL,
        userComment TEXT,
        userRating REAL
      )
    ''');

    // 2. Table des Villes favorites
    await db.execute('''
      CREATE TABLE cities (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        country TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      )
    ''');
  }

  // --- GESTION DES POI (PLACES) ---

  Future<int> insertPlace(Place place) async {
    final db = await instance.database;
    return await db.insert('places', place.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deletePlace(String placeId) async {
    final db = await instance.database;
    return await db.delete('places', where: 'placeId = ?', whereArgs: [placeId]);
  }

  Future<bool> isPlaceFavorite(String placeId) async {
    final db = await instance.database;
    final maps = await db.query('places', where: 'placeId = ?', whereArgs: [placeId]);
    return maps.isNotEmpty;
  }
  
  Future<List<Place>> getAllPlaces() async {
     final db = await instance.database;
     final result = await db.query('places');
     return result.map((json) => Place.fromMap(json)).toList();
  }

  // --- GESTION DES VILLES (CITIES) ---

  Future<int> insertCity(City city) async {
    final db = await instance.database;
    return await db.insert('cities', city.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteCity(String id) async {
    final db = await instance.database;
    return await db.delete('cities', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isCityFavorite(String id) async {
    final db = await instance.database;
    final maps = await db.query('cities', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty;
  }

  Future<List<City>> getFavoriteCities() async {
    final db = await instance.database;
    final result = await db.query('cities');
    return result.map((json) => City.fromMap(json)).toList();
  }

  Future<List<Place>> getPlacesForCity(String cityName) async {
    final db = await instance.database;
    // On filtre par le nom de la ville
    final result = await db.query(
      'places', 
      where: 'cityName = ?', 
      whereArgs: [cityName],
      orderBy: 'id DESC' // Les plus récents en premier
    );
    return result.map((json) => Place.fromMap(json)).toList();
  }

}