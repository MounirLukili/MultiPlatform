import 'package:flutter/material.dart';
import '../models/place_model.dart';

class PoiCarousel extends StatelessWidget {
  final List<Place> places;
  final Function(Place) onPlaceChanged; // Callback quand on change de lieu
  final Function(Place) onPlaceTap;     // Callback quand on clique (pour ouvrir le détail)

  const PoiCarousel({
    super.key,
    required this.places,
    required this.onPlaceChanged,
    required this.onPlaceTap,
  });

  @override
  Widget build(BuildContext context) {
    // PageController pour contrôler le défilement et l'effet de "snap"
    final PageController controller = PageController(viewportFraction: 0.85);

    return SizedBox(
      height: 200, // Hauteur de la zone carousel
      child: PageView.builder(
        controller: controller,
        itemCount: places.length,
        onPageChanged: (index) {
          onPlaceChanged(places[index]);
        },
        itemBuilder: (context, index) {
          final place = places[index];
          return _buildPoiCard(context, place);
        },
      ),
    );
  }

  Widget _buildPoiCard(BuildContext context, Place place) {
    return GestureDetector(
      onTap: () => onPlaceTap(place),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20), // Marge pour l'ombre
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1. IMAGE (Gauche)
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: SizedBox(
                width: 120,
                height: double.infinity,
                child: place.imageUrl.isNotEmpty
                    ? Image.network(
                        place.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_,__,___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)),
                      )
                    : Container(color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)),
              ),
            ),
            
            // 2. INFOS (Droite)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      place.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        place.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          place.rating.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "(${place.noteCount})",
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}