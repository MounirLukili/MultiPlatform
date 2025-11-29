// lib/screens/city_search_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Pour utiliser Timer
import '../providers/city_provider.dart';
import '../models/city_model.dart';
// Note: Pas besoin d'importer FlutterMap ou Lottie ici, car la MainPage gère l'affichage.

class CitySearchScreen extends StatefulWidget {
  const CitySearchScreen({super.key});

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  // Déclenché à chaque frappe dans la barre de recherche
  void _onSearchChanged(String query) {
    // Annule le timer précédent s'il existe
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Démarrer un nouveau timer
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Déclenche la recherche seulement après 500ms d'inactivité
      Provider.of<CityProvider>(context, listen: false).searchCity(query);
    });
  }

  // Gère la sélection d'une ville dans les résultats
  Future<void> _selectCity(City city) async {
    final cityProvider = Provider.of<CityProvider>(context, listen: false);
    
    // 1. Définir la nouvelle ville (récupère la météo et notifie les listeners)
    await cityProvider.setCity(city);

    // 2. Retourner à la page principale (Map)
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    // Annuler le timer et le controller de texte lors de la suppression du widget
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Écoute les résultats et l'état de la recherche
    return Consumer<CityProvider>(
      builder: (context, cityProvider, child) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: true, // Bouton retour
            title: TextField(
              controller: _controller,
              autofocus: true, // Met le focus sur le champ de saisie à l'ouverture
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Entrez le nom d\'une ville...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                suffixIcon: cityProvider.isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          body: _buildBody(context, cityProvider),
        );
      },
    );
  }

  // Construit le corps de l'écran (résultats, messages d'erreur ou de chargement)
  Widget _buildBody(BuildContext context, CityProvider cityProvider) {
    if (cityProvider.isSearching) {
      return const Center(child: Text("Recherche en cours..."));
    }

    if (cityProvider.errorMessage != null && cityProvider.searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            cityProvider.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
      );
    }
    
    if (cityProvider.searchResults.isEmpty && _controller.text.isNotEmpty) {
       return const Center(child: Text("Aucun résultat trouvé."));
    }

    if (cityProvider.searchResults.isEmpty) {
       return const Center(child: Text("Commencez à taper le nom d'une ville pour rechercher."));
    }


    // Affichage des résultats
    return ListView.builder(
      itemCount: cityProvider.searchResults.length,
      itemBuilder: (context, index) {
        final city = cityProvider.searchResults[index];
        return ListTile(
          leading: const Icon(Icons.location_city, color: Colors.blue),
          title: Text(city.name),
          subtitle: Text(city.country),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _selectCity(city),
        );
      },
    );
  }
}