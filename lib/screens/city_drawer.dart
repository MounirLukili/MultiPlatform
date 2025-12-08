import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/city_model.dart';
import '../providers/city_provider.dart';

class CityDrawer extends StatefulWidget {
  const CityDrawer({super.key});

  @override
  State<CityDrawer> createState() => _CityDrawerState();
}

class _CityDrawerState extends State<CityDrawer> {
  // rafraichir la liste apres une suppression
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_city, color: Colors.white, size: 50),
                  SizedBox(height: 10),
                  Text(
                    "Mes Villes",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<City>>(
              key: ValueKey(_refreshKey),
              future: DatabaseService.instance.getFavoriteCities(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final cities = snapshot.data ?? [];

                if (cities.isEmpty) {
                  return const Center(child: Text("Aucune ville visitée pour l'instant."));
                }

                return ListView.builder(
                  itemCount: cities.length,
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    return ListTile(
                      leading: const Icon(Icons.history, color: Colors.grey),
                      title: Text(city.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(city.country),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          // Suppression de la ville
                          await DatabaseService.instance.deleteCity(city.id);
                          setState(() => _refreshKey++); // Reload la liste
                        },
                      ),
                      onTap: () {
                        // Charger cette ville
                        Navigator.pop(context); // Fermer le drawer
                        Provider.of<CityProvider>(context, listen: false).setCity(city);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}