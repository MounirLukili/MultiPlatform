import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/city_provider.dart';
import '../models/city_model.dart';

class CitySearchScreen extends StatefulWidget {
  const CitySearchScreen({super.key});

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  
  // Un "verrou" pour empecher la boucle infinie
  bool _isRedirecting = false;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Si on change le texte, on "déverrouille" la redirection
    if (_isRedirecting) {
      setState(() => _isRedirecting = false);
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<CityProvider>(context, listen: false).searchCity(query);
    });
  }

  Future<void> _selectCity(City city) async {
    final cityProvider = Provider.of<CityProvider>(context, listen: false);
    await cityProvider.setCity(city);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CityProvider>(
      builder: (context, cityProvider, child) {
        
        // On vérifie les conditions pour l'auto-sélect
        bool shouldAutoSelect = !cityProvider.isSearching && 
                                cityProvider.searchResults.length == 1 && 
                                _controller.text.isNotEmpty;

        if (shouldAutoSelect) {
          // Si on n'a pas encore lancé la redirection...
          if (!_isRedirecting) {
            _isRedirecting = true; // On verrouille immédiatement
            
            // On lance l'action APRÈS l'affichage de l'écran de chargement
            WidgetsBinding.instance.addPostFrameCallback((_) {
               _selectCity(cityProvider.searchResults.first);
            });
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else {
          if (_isRedirecting) {
             Future.microtask(() {
               if (mounted) setState(() => _isRedirecting = false);
             });
          }
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: true, 
            title: TextField(
              controller: _controller,
              autofocus: true,
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