import 'package:flutter/material.dart';
import 'dart:ui'; // Pour BackdropFilter
import '../models/place_model.dart';

class AnimatedPlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const AnimatedPlaceCard({super.key, required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 15, bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5)
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image avec Hero
              Hero(
                tag: 'place-img-${place.title}',
                transitionOnUserGestures: true,
                child: place.imageUrl.isNotEmpty
                    ? Image.network(place.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey.shade800))
                    : Container(color: Colors.grey.shade800, child: const Icon(Icons.image, color: Colors.white24, size: 50)),
              ),

              // Dégradé sombre en bas
              Positioned(
                bottom: 0, left: 0, right: 0, height: 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                    ),
                  ),
                ),
              ),

              // Titre et Catégorie
              Positioned(
                bottom: 12, left: 12, right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        place.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)])
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.category, color: Colors.amber, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.category.toUpperCase(),
                            style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Note (Rating) en haut à droite
              Positioned(
                top: 10, right: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.black.withOpacity(0.4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 4),
                          Material(
                            color: Colors.transparent,
                            child: Text(place.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}