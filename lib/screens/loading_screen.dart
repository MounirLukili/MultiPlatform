// lib/screens/landing_screen.dart

import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:provider/provider.dart';
import '../providers/city_provider.dart';

class ExploreLandingScreen extends StatelessWidget {
  const ExploreLandingScreen({super.key});

  // Méthode pour gérer le clic sur le bouton
  Future<void> _onStart(BuildContext context) async {
    final cityProvider = Provider.of<CityProvider>(context, listen: false);

    // Démarrer la recherche de la ville actuelle et de la météo
    await cityProvider.findCurrentCityAndWeather(context);
    
    // Si la recherche a réussi (currentCity n'est pas null), naviguer vers la page principale
    if (cityProvider.currentCity != null) {
      Navigator.of(context).pushReplacementNamed('/main');
    } else {
      // Afficher un dialogue d'erreur si l'API ou la géolocalisation a échoué
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cityProvider.errorMessage ?? "Erreur inconnue lors de la localisation."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // 1. Animation du nom de l'application (comme demandé)
              AnimatedTextKit(
                animatedTexts: [
                  TyperAnimatedText(
                    'Explorez Votre Ville',
                    textStyle: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
                totalRepeatCount: 1,
                pause: const Duration(milliseconds: 500),
                displayFullTextOnTap: true,
                stopPauseOnTap: true,
              ),

              const SizedBox(height: 50),

              const Text(
                "Votre guide personnel pour découvrir les trésors cachés autour de vous.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              ),

              const SizedBox(height: 80),

              // 2. Bouton Commencer
              Consumer<CityProvider>(
                builder: (context, cityProvider, child) {
                  // Affiche un indicateur de chargement pendant la géolocalisation
                  if (cityProvider.isLoading) {
                    return const CircularProgressIndicator();
                  }
                  
                  return ElevatedButton.icon(
                    onPressed: () => _onStart(context),
                    icon: const Icon(Icons.travel_explore),
                    label: const Text('Commencer l\'exploration'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}