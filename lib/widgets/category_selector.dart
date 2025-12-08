import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/poi_provider.dart';
import '../models/city_model.dart';

class CategorySelector extends StatelessWidget {
  final City city;
  final Function(bool isSelected) onCategoryTap; // Callback pour informer le parent

  const CategorySelector({super.key, required this.city, required this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'key': 'favoris', 'icon': Icons.favorite, 'color': Colors.red, 'label': 'Favoris'},
      {'key': 'manger', 'icon': Icons.restaurant, 'color': Colors.orange, 'label': 'Manger'},
      {'key': 'cafés', 'icon': Icons.local_cafe, 'color': Colors.brown, 'label': 'Cafés'},
      {'key': 'culture', 'icon': Icons.museum, 'color': Colors.purple, 'label': 'Culture'},
      {'key': 'nature', 'icon': Icons.park, 'color': Colors.green, 'label': 'Nature'},
      {'key': 'shopping', 'icon': Icons.shopping_bag, 'color': Colors.pink, 'label': 'Shopping'},
      {'key': 'hôtels', 'icon': Icons.hotel, 'color': Colors.indigo, 'label': 'Hôtels'},
      {'key': 'santé', 'icon': Icons.local_pharmacy, 'color': Colors.teal, 'label': 'Santé'},
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Consumer<PoiProvider>(
            builder: (context, poiProvider, child) {
              final isSelected = poiProvider.activeCategory == cat['key'];
              return GestureDetector(
                onTap: () {
                  poiProvider.searchPois(city.latitude, city.longitude, cat['key'] as String, cityName: city.name);
                  // On informe le parent si on affiche le carrousel ou non
                  onCategoryTap(!isSelected);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? (cat['color'] as Color) : Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat['icon'] as IconData, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        cat['label'] as String,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}