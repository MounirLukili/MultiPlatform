import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sqlite_api.dart';

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
    // Initialisation spécifique de la bdd selon la plateforme
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit(); // Initialise SQLite
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = filePath; // Stocké dans IndexedDB
    } else {
      final dbPath = await databaseFactory.getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
      ),
    );
  }

  Future<void> _createDB(Database db, int version) async {
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

  // ------------------------
  // PLACES
  // ------------------------

  Future<int> insertPlace(Place place) async {
    final db = await instance.database;
    return await db.insert(
      'places',
      place.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

  Future<List<Place>> getPlacesForCity(String cityName) async {
    final db = await instance.database;
    final result = await db.query(
      'places',
      where: 'cityName = ?',
      whereArgs: [cityName],
      orderBy: 'id DESC',
    );
    return result.map((json) => Place.fromMap(json)).toList();
  }

  // ------------------------
  // CITIES
  // ------------------------

  Future<int> insertCity(City city) async {
    final db = await instance.database;
    return await db.insert(
      'cities',
      city.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteCity(String id) async {
    final db = await instance.database;
    return await db.delete('cities', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isCityFavorite(String id) async {
    final db = await instance.database;
    final result = await db.query('cities', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty;
  }

  Future<List<City>> getFavoriteCities() async {
    final db = await instance.database;
    final result = await db.query('cities');
    return result.map((json) => City.fromMap(json)).toList();
  }
}
