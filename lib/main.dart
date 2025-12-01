// lib/main.dart

import 'dart:io'; // Pour vérifier si on est sur Desktop
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Pour kIsWeb (Vérif Web)
import 'package:provider/provider.dart';

// Imports pour la base de données
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; 
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // ⚠️ IMPORT INDISPENSABLE POUR LE WEB

import 'screens/landing_screen.dart';
import 'screens/main_page.dart'; 
import 'screens/city_search_screen.dart';
import 'providers/city_provider.dart'; 
import 'providers/poi_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚠️ CONFIGURATION CRITIQUE POUR LA BASE DE DONNÉES
  
  if (kIsWeb) {
    // 1. SI ON EST SUR CHROME (WEB)
    // On force l'utilisation de la version Web (WASM)
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // 2. SI ON EST SUR ORDI (Windows/Mac/Linux)
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // 3. SI ON EST SUR ANDROID/IOS : Rien à faire, c'est automatique.

  runApp(const ExplorezVotreVilleWrapper());
}

class ExplorezVotreVilleWrapper extends StatelessWidget {
  const ExplorezVotreVilleWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CityProvider()),
        ChangeNotifierProvider(create: (_) => PoiProvider()),
      ],
      child: const ExplorezVotreVille(),
    );
  }
}

class ExplorezVotreVille extends StatelessWidget {
  const ExplorezVotreVille({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Explorez Votre Ville',
      theme: ThemeData(
        brightness: Brightness.light, 
        primarySwatch: Colors.blue, 
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark, 
        useMaterial3: true
      ),
      themeMode: ThemeMode.system, 
      initialRoute: '/',
      routes: {
        '/': (context) => const ExploreLandingScreen(), 
        '/main': (context) => const MainPage(), 
        '/search_city': (context) => const CitySearchScreen(),
      },
    );
  }
}