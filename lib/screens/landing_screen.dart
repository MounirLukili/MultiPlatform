// lib/screens/landing_screen.dart

import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart'; 
import '../providers/city_provider.dart';

class ExploreLandingScreen extends StatelessWidget {
  const ExploreLandingScreen({super.key});

  Future<void> _onStart(BuildContext context) async {
    final cityProvider = Provider.of<CityProvider>(context, listen: false);

    // Démarrer la recherche de la ville actuelle et de la météo
    // L'état isLoading passe à true ici
    await cityProvider.findCurrentCityAndWeather(context);
    
    // ⚠️ La navigation est gérée APRES la fin de l'opération asynchrone
    // et en vérifiant l'état final.
    if (cityProvider.currentCity != null) {
      // Si la ville a été trouvée, naviguer vers la page principale
      Navigator.of(context).pushReplacementNamed('/main');
    } else {
      // Afficher l'erreur (si la géolocalisation ou la météo a échoué)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cityProvider.errorMessage ?? "Erreur de localisation. Veuillez vérifier vos paramètres."),
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
              // Animation du nom de l'application (Fonctionnalité 1.1)
              AnimatedTextKit(
                animatedTexts: [
                  TyperAnimatedText(
                    'Explorez Votre Ville',
                    textStyle: TextStyle(
                      fontSize: 36.0,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
                totalRepeatCount: 1,
                pause: const Duration(milliseconds: 500),
                displayFullTextOnTap: true,
                stopPauseOnTap: true,
              ),

              const SizedBox(height: 60),

              const Text(
                "Lancez l'exploration pour découvrir les lieux d'intérêt autour de vous.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              ),

              const SizedBox(height: 80),

              // Bouton Commencer (Contrôlé par l'état de chargement du CityProvider)
              Consumer<CityProvider>(
                builder: (context, cityProvider, child) {
                  // AFFICHAGE DE L'ANIMATION LOTTIE LORS DU CHARGEMENT
                  if (cityProvider.isLoading) {
                    return Column(
                      children: [
                        Lottie.asset(
                          'assets/loading.json', // Assurez-vous d'avoir ce chemin correct
                          width: 150,
                          height: 150,
                        ),
                        const SizedBox(height: 15),
                        const Text("Recherche de votre position actuelle...", style: TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    );
                  }
                  
                  // Bouton "Commencer"
                  return ElevatedButton.icon(
                    onPressed: () => _onStart(context),
                    icon: const Icon(Icons.location_searching, size: 24),
                    label: const Text('Commencer l\'exploration'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
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