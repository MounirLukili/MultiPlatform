// main.dart for ExplorezVotreVille
// Point d'entrée de l'application. Initialise les bindings et l'architecture (Provider, Thèmes).

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:provider/provider.dart';

import 'screens/landing_screen.dart';
import 'screens/main_page.dart'; 
import 'screens/city_search_screen.dart'; // ⚠️ NOUVELLE IMPORTATION
import 'providers/city_provider.dart'; 

// Cette clé n'est plus utilisée pour la carte (FlutterMap), mais pourrait l'être pour d'autres services Google.
const String googleMapsApiKey = "VOTRE_CLE_API_GOOGLE_MAPS_ICI"; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const ExplorezVotreVilleWrapper());
}

// Wrapper pour intégrer MultiProvider (Gestion d'état)
class ExplorezVotreVilleWrapper extends StatelessWidget {
  const ExplorezVotreVilleWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CityProvider()),
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
      // Configuration des routes nommées (Fonctionnalité 1.9)
      routes: {
        '/': (context) => const ExploreLandingScreen(), 
        '/main': (context) => const MainPage(), 
        '/search_city': (context) => const CitySearchScreen(), // ⚠️ NOUVELLE ROUTE
      },
    );
  }
}