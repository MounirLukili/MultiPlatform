import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../providers/city_provider.dart';
import '../services/preferences_service.dart';
import '../models/city_model.dart';

class ExploreLandingScreen extends StatefulWidget {
  const ExploreLandingScreen({super.key});

  @override
  State<ExploreLandingScreen> createState() => _ExploreLandingScreenState();
}

class _ExploreLandingScreenState extends State<ExploreLandingScreen> with SingleTickerProviderStateMixin {
  final PreferencesService _prefs = PreferencesService();
  bool _isCheckingPrefs = true;

  late AnimationController _btnController;
  late Animation<double> _btnScaleAnim;

  @override
  void initState() {
    super.initState();
    _checkDefaultCity();

    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _btnScaleAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _btnController.dispose();
    super.dispose();
  }

  Future<void> _checkDefaultCity() async {
    final defaultCity = await _prefs.getDefaultCity();
    if (defaultCity != null && mounted) {
      final cityProvider = Provider.of<CityProvider>(context, listen: false);
      await cityProvider.setCity(defaultCity);
      if (mounted) Navigator.of(context).pushReplacementNamed('/main');
    } else {
      if (mounted) setState(() => _isCheckingPrefs = false);
    }
  }

  Future<void> _onStart(BuildContext context) async {
    final cityProvider = Provider.of<CityProvider>(context, listen: false);
    await cityProvider.findCurrentCityAndWeather(context);

    if (cityProvider.currentCity != null) {
      if (mounted) _showChoiceDialog(context, cityProvider.currentCity!);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cityProvider.errorMessage ?? "Erreur de localisation"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChoiceDialog(BuildContext context, City detectedCity) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Bienvenue !"),
        content: Text("Nous vous avons localisé à ${detectedCity.name}.\nVoulez-vous définir cette ville comme votre ville par défaut ?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _goToSearchAndSetDefault(context);
            },
            child: const Text("Non, choisir une autre"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _prefs.saveDefaultCity(detectedCity);
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.of(context).pushReplacementNamed('/main');
              }
            },
            child: const Text("Oui, c'est ma ville"),
          ),
        ],
      ),
    );
  }

  Future<void> _goToSearchAndSetDefault(BuildContext context) async {
    await Navigator.of(context).pushNamed('/search_city');
    final cityProvider = Provider.of<CityProvider>(context, listen: false);
    if (cityProvider.currentCity != null) {
      await _prefs.saveDefaultCity(cityProvider.currentCity!);
      if (mounted) Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPrefs) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black, // evite le flash blanc au chargement
      extendBodyBehindAppBar: true,  // L'image passe sous la barre de statut (haut)
      resizeToAvoidBottomInset: false, // evite que le clavier  ne casse le design
      
      body: Stack(
        fit: StackFit.expand, // Force le Stack à prendre TOUT l'écran
        children: [
          //IMAGE DE FOND
          // On utilise un Container avec height/width infinity pour être sûr
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.network(
              'https://images.unsplash.com/photo-1519501025264-65ba15a82390?q=80&w=1000&auto=format&fit=crop',
              fit: BoxFit.cover, // Remplit tout l'espace en coupant les bords si nécessaire
              errorBuilder: (c, e, s) => Container(color: const Color(0xFF1A1A2E)),
            ),
          ),

          // 2. FILTRE SOMBRE (Gradient)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),

          // 3. CONTENU (Dans une SafeArea pour ne pas être caché par l'encoche)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  Icon(Icons.travel_explore, size: 80, color: Colors.white.withOpacity(0.9)),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 120,
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        fontSize: 42.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: [Shadow(blurRadius: 15, color: Colors.black, offset: Offset(0, 5))],
                      ),
                      child: AnimatedTextKit(
                        animatedTexts: [
                          FadeAnimatedText('EXPLOREZ\nVOTRE VILLE', textAlign: TextAlign.center, duration: const Duration(seconds: 4)),
                          FadeAnimatedText('DÉCOUVREZ\nL\'INATTENDU', textAlign: TextAlign.center, duration: const Duration(seconds: 4)),
                        ],
                        repeatForever: true,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Votre guide personnel pour découvrir les trésors cachés autour de vous.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5, fontWeight: FontWeight.w300),
                  ),

                  const Spacer(flex: 3),

                  

              Consumer<CityProvider>(
                builder: (context, cityProvider, child) {
                  // CAS 1 : CHARGEMENT 
                  if (cityProvider.isLoading) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animation Lottie 
                        SizedBox(
                          height: 250, 
                          child: Lottie.asset(
                            'assets/loading.json',
                            fit: BoxFit.contain, // Garde les proportions
                            // Si le fichier Lottie ne charge pas, on affiche un loader classique doré
                            errorBuilder: (c, e, s) => Transform.scale(
                              scale: 1.5, 
                              child: const CircularProgressIndicator(color: Colors.amber),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20), // Un peu plus d'espace
                        
                        // Texte stylisé avec une ombre pour ressortir sur le fond
                        const Text(
                          "Recherche de votre position...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18, 
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2, // Espacement des lettres pour le style "Premium"
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 2))
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  //BOUTON COMMENCER
                  return ScaleTransition(
                    scale: _btnScaleAnim,
                    child: ElevatedButton(
                      onPressed: () => _onStart(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        elevation: 10,
                        shadowColor: Colors.amber.withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'COMMENCER L\'AVENTURE', 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                  );
                },
              ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}