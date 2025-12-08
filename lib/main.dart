
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'screens/landing_screen.dart';
import 'screens/main_page.dart'; 
import 'screens/city_search_screen.dart';
import 'providers/city_provider.dart'; 
import 'providers/poi_provider.dart';
import 'providers/theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // ⚠️ AJOUT
      ],
      // On utilise un Consumer ici pour reconstruire l'app quand le thème change
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Explorez Votre Ville',
            
            // Gestion du thème dynamique
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              brightness: Brightness.light, 
              primarySwatch: Colors.blue, 
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark, 
              useMaterial3: true
            ),
            
            initialRoute: '/',
            routes: {
              '/': (context) => const ExploreLandingScreen(), 
              '/main': (context) => const MainPage(), 
              '/search_city': (context) => const CitySearchScreen(),
            },
          );
        },
      ),
    );
  }
}